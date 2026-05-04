import uuid

# Define constants
PROJECT_FILE_PATH = "Games Collection.xcodeproj/project.pbxproj"

# IDs from the project file
MAIN_GROUP_ID = "BED0076D2EFFFB2B008E5FDB"
GAMES_COLLECTION_GROUP_ID = "BED007782EFFFB2B008E5FDB" # The group pointing to "Games Collection" folder
SOURCES_BUILD_PHASE_ID = "BED007722EFFFB2B008E5FDB"

# New Files to Add
FILES_TO_ADD = [
    {"name": "GameRecommenderView.swift", "path": "GameRecommenderView.swift", "type": "sourcecode.swift"},
    {"name": "Services", "path": "Services", "type": "wrapper.pb-project", "is_folder": True} # Wait, Services is a folder with swift files inside?
]

# We need to add the swift files INSIDE Services individually to the build phase, 
# but we can add the "Services" GROUP to the file browser.
# Let's adjust: We will create a new PBXGroup for "Services" and add the files inside it.

def generate_id():
    return uuid.uuid4().hex[:24].upper()

def main():
    with open(PROJECT_FILE_PATH, "r") as f:
        content = f.read()

    # 1. Create IDs
    recommender_fileref = generate_id()
    recommender_buildfile = generate_id()
    
    services_group_id = generate_id()
    
    lifecycle_fileref = generate_id()
    lifecycle_buildfile = generate_id()
    
    player_fileref = generate_id()
    player_buildfile = generate_id()

    # 2. Construct PBXFileReference Section additions
    # GameRecommenderView.swift
    recommender_ref_entry = f'		{recommender_fileref} /* GameRecommenderView.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = GameRecommenderView.swift; sourceTree = "<group>"; }};'
    
    # Services/AppLifecycleManager.swift
    lifecycle_ref_entry = f'		{lifecycle_fileref} /* AppLifecycleManager.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = AppLifecycleManager.swift; sourceTree = "<group>"; }};'
    
    # Services/GlobalPlayerManager.swift
    player_ref_entry = f'		{player_fileref} /* GlobalPlayerManager.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = GlobalPlayerManager.swift; sourceTree = "<group>"; }};'

    # 3. Construct PBXBuildFile Section additions
    recommender_build_entry = f'		{recommender_buildfile} /* GameRecommenderView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {recommender_fileref} /* GameRecommenderView.swift */; }};'
    lifecycle_build_entry = f'		{lifecycle_buildfile} /* AppLifecycleManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {lifecycle_fileref} /* AppLifecycleManager.swift */; }};'
    player_build_entry = f'		{player_buildfile} /* GlobalPlayerManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {player_fileref} /* GlobalPlayerManager.swift */; }};'

    # 4. Construct PBXGroup additions (Services Group)
    services_group_entry = f'''		{services_group_id} /* Services */ = {{
			isa = PBXGroup;
			children = (
				{lifecycle_fileref} /* AppLifecycleManager.swift */,
				{player_fileref} /* GlobalPlayerManager.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		}};'''

    # --- APPLY CHANGES ---

    lines = content.split('\n')
    new_lines = []
    
    in_fileref_section = False
    in_buildfile_section = False
    in_group_section = False
    
    filerefs_added = False
    buildfiles_added = False
    groups_added = False
    
    for line in lines:
        new_lines.append(line)
        
        # Add Build Files
        if "/* Begin PBXBuildFile section */" in line and not buildfiles_added:
            new_lines.append(recommender_build_entry)
            new_lines.append(lifecycle_build_entry)
            new_lines.append(player_build_entry)
            buildfiles_added = True
            
        # Add File References
        if "/* Begin PBXFileReference section */" in line and not filerefs_added:
            new_lines.append(recommender_ref_entry)
            new_lines.append(lifecycle_ref_entry)
            new_lines.append(player_ref_entry)
            filerefs_added = True
            
        # Add Services Group definition
        if "/* Begin PBXGroup section */" in line and not groups_added:
            new_lines.append(services_group_entry)
            groups_added = True

    # 5. Link in PBXGroup (Games Collection Group)
    # We need to find the group {GAMES_COLLECTION_GROUP_ID} and add children
    final_lines = []
    
    looking_for_games_collection_children = False
    
    for line in new_lines:
        final_lines.append(line)
        
        if GAMES_COLLECTION_GROUP_ID in line and "isa = PBXFileSystemSynchronizedRootGroup" in line:
             # Wait, it is a Synchronized Root Group? 
             # If it is Synchronized (Folder based), we might NOT need to modify pbxproj at all!
             # Xcode 16+ Synchronized Groups automatically pick up files on disk.
             # Let's check the file content again.
             pass

    # Wait, I saw "isa = PBXFileSystemSynchronizedRootGroup" in the file read.
    # BED007782EFFFB2B008E5FDB /* Games Collection */ = {
    # 	isa = PBXFileSystemSynchronizedRootGroup;
    # 	path = "Games Collection";
    # 	sourceTree = "<group>";
    # };
    
    # If it is a PBXFileSystemSynchronizedRootGroup, Xcode automatically mirrors the folder structure!
    # That means I DO NOT need to edit the project file manually for files inside "Games Collection" folder.
    # They should appear automatically if the folder structure matches.
    
    # Why did the user say they don't see them?
    # Maybe because they haven't refreshed? Or because the Services folder is new?
    
    # Let's verify if I should proceed with manual editing.
    # If "Games Collection" is synchronized, adding files manually to it in pbxproj might cause conflicts or be ignored.
    
    return

if __name__ == "__main__":
    main()
