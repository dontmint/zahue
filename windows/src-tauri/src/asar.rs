use serde_json::Value;
use std::fs;
use std::io::{self, Read};
use std::path::Path;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AsarError {
    #[error("invalid ASAR header")]
    InvalidHeader,
    #[error("missing or invalid ASAR entry: {0}")]
    MissingFile(String),
    #[error("ASAR I/O: {0}")]
    Io(String),
    #[error(transparent)]
    StdIo(#[from] io::Error),
    #[error(transparent)]
    Json(#[from] serde_json::Error),
}

/// Extract an Electron ASAR archive (packed files only; skip `unpacked` entries).
/// Format: 8-byte size pickle + header pickle (JSON string) + file bytes.
pub fn extract_all(archive: &Path, destination: &Path) -> Result<(), AsarError> {
    let mut file = fs::File::open(archive)?;
    let mut data = Vec::new();
    file.read_to_end(&mut data)?;
    if data.len() < 16 {
        return Err(AsarError::InvalidHeader);
    }

    // size pickle: [payloadSize:UInt32][headerPickleLength:UInt32]
    let header_pickle_length = read_u32(&data, 4)? as usize;
    let header_pickle_start: usize = 8;
    let header_pickle_end = header_pickle_start
        .checked_add(header_pickle_length)
        .ok_or(AsarError::InvalidHeader)?;
    if header_pickle_end > data.len() {
        return Err(AsarError::InvalidHeader);
    }

    let header_pickle = &data[header_pickle_start..header_pickle_end];
    // string pickle: [payloadSize:UInt32][strLen:Int32][bytes...]
    if header_pickle.len() < 8 {
        return Err(AsarError::InvalidHeader);
    }
    let str_len = read_i32(header_pickle, 4)?;
    if str_len < 0 || 8 + str_len as usize > header_pickle.len() {
        return Err(AsarError::InvalidHeader);
    }
    let json_bytes = &header_pickle[8..8 + str_len as usize];
    let root: Value = serde_json::from_slice(json_bytes)?;
    let files = root
        .get("files")
        .and_then(|v| v.as_object())
        .ok_or(AsarError::InvalidHeader)?;

    let base_offset = 8 + header_pickle_length;
    fs::create_dir_all(destination)?;
    walk(files, "", &data, base_offset, destination)?;
    Ok(())
}

fn walk(
    node: &serde_json::Map<String, Value>,
    relative_path: &str,
    archive: &[u8],
    base_offset: usize,
    destination: &Path,
) -> Result<(), AsarError> {
    for (name, value) in node {
        let Some(entry) = value.as_object() else {
            continue;
        };
        let child_rel = if relative_path.is_empty() {
            name.clone()
        } else {
            format!("{relative_path}/{name}")
        };
        let child_path = destination.join(&child_rel);

        if let Some(children) = entry.get("files").and_then(|v| v.as_object()) {
            fs::create_dir_all(&child_path)?;
            walk(children, &child_rel, archive, base_offset, destination)?;
            continue;
        }

        // unpacked files live beside the archive; skip
        if entry.get("unpacked").and_then(|v| v.as_bool()) == Some(true) {
            continue;
        }

        let offset = entry
            .get("offset")
            .and_then(|v| v.as_str())
            .and_then(|s| s.parse::<usize>().ok())
            .ok_or_else(|| AsarError::MissingFile(child_rel.clone()))?;
        let size = entry
            .get("size")
            .and_then(|v| {
                v.as_u64()
                    .map(|n| n as usize)
                    .or_else(|| v.as_i64().map(|n| n as usize))
                    .or_else(|| v.as_str().and_then(|s| s.parse().ok()))
            })
            .ok_or_else(|| AsarError::MissingFile(child_rel.clone()))?;

        let start = base_offset
            .checked_add(offset)
            .ok_or_else(|| AsarError::Io(format!("ASAR slice out of range for {child_rel}")))?;
        let end = start
            .checked_add(size)
            .ok_or_else(|| AsarError::Io(format!("ASAR slice out of range for {child_rel}")))?;
        if start < base_offset || end > archive.len() {
            return Err(AsarError::Io(format!(
                "ASAR slice out of range for {child_rel}"
            )));
        }

        if let Some(parent) = child_path.parent() {
            fs::create_dir_all(parent)?;
        }
        fs::write(&child_path, &archive[start..end])?;

        if entry.get("executable").and_then(|v| v.as_bool()) == Some(true) {
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                let mut perms = fs::metadata(&child_path)?.permissions();
                perms.set_mode(0o755);
                fs::set_permissions(&child_path, perms)?;
            }
        }
    }
    Ok(())
}

fn read_u32(data: &[u8], offset: usize) -> Result<u32, AsarError> {
    let end = offset
        .checked_add(4)
        .ok_or(AsarError::InvalidHeader)?;
    if end > data.len() {
        return Err(AsarError::InvalidHeader);
    }
    Ok(u32::from_le_bytes(data[offset..end].try_into().unwrap()))
}

fn read_i32(data: &[u8], offset: usize) -> Result<i32, AsarError> {
    let end = offset
        .checked_add(4)
        .ok_or(AsarError::InvalidHeader)?;
    if end > data.len() {
        return Err(AsarError::InvalidHeader);
    }
    Ok(i32::from_le_bytes(data[offset..end].try_into().unwrap()))
}
