namespace SlidingDiscTags
{
	const FName SlidingDiscMovement = n"SlidingDiscMovement";
	const FName GrindingDiscMovement = n"GrindingDiscMovement";
}

namespace SlidingDiscDevToggles
{
	const FHazeDevToggleCategory SlidingDiscCategory = FHazeDevToggleCategory(n"Sliding Disc");
	const FName DebugDrawSubcategory = n"Draw";
	const FHazeDevToggleBool DrawDisc = FHazeDevToggleBool(SlidingDiscCategory, DebugDrawSubcategory, n"Sliding Disc");
	const FHazeDevToggleBool DisableDiscMovement = FHazeDevToggleBool(SlidingDiscCategory, n"Disable Disc Movement");
	const FHazeDevToggleBool DrawBoat = FHazeDevToggleBool(SlidingDiscCategory, DebugDrawSubcategory, n"Boat");
	const FHazeDevToggleBool SoloSteering = FHazeDevToggleBool(SlidingDiscCategory, n"Solo Steering");
}