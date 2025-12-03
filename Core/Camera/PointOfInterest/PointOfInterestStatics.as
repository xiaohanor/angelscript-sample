
/**
 * Force camera to look at given point of interest if able to.
 * FocusTarget; Uses the world offset unless a 'FocusActor' or 'FocusComponent' is provided
 * Duration; >= 0; will remove the POI after the duration has passed
 * bClearOnInput; if the player gives input, the POI is removed using the players 'CameraPointOfInterestSettings'
 * InputPauseTime; >= 0; will stop the POI for the pause time, and then return back 
*/
UFUNCTION(Category = "PointOfInterest", Meta = (AutoSplit = "PoiSettings"))
mixin void ApplyPointOfInterest(AHazePlayerCharacter Player, FInstigator Instigator, 
	FHazePointOfInterestFocusTargetInfo FocusTarget, 
	FApplyPointOfInterestSettings PoiSettings,
	float BlendInTime = 2,
	EHazeCameraPriority Priority = EHazeCameraPriority::Low)
{
	auto POI = Player.CreatePointOfInterest();
	POI.FocusTarget = FocusTarget;
	POI.Settings = PoiSettings;
	POI.Apply(Instigator, BlendInTime, Priority);
}

/**
 * Works just like a regular point of interest, but camera control will be temporarily regained when
 * player adjusts the camera manually. After no input is given the POI behavior will return to normal.
 */
UFUNCTION(Category = "PointOfInterest", Meta = (AutoSplit = "PoiSettings"))
mixin void ApplyPointOfInterestSuspendOnInput(AHazePlayerCharacter Player, FInstigator Instigator,
	FHazePointOfInterestFocusTargetInfo FocusTarget, 
	FApplyPointOfInterestSettings PoiSettings,
	FPointOfInterestInputSuspensionSettings&in SuspendOnInput,
	float BlendInTime = 2,
	EHazeCameraPriority Priority = EHazeCameraPriority::Low)
{
	auto POI = Player.CreatePointOfInterest();
	POI.FocusTarget = FocusTarget;
	POI.Settings = PoiSettings;
	POI.Settings.InputSuspension = SuspendOnInput;
	POI.Settings.InputSuspension.bUseInputSuspension = true;
	POI.Apply(Instigator, BlendInTime, Priority);
}

/**
 * Camera will look at given point. Player can move camera within the clamps to a degree.
 * FocusTarget; Uses the world offset unless a 'FocusActor' or 'FocusComponent' is provided
 * Duration; >= 0; will remove the POI after the duration has passed
 * bForceDuringBlendIn; the player will not be able to look away until the POI is fully blended in
 * bClearOnInput; if the player gives input, the POI is removed using the players 'CameraPointOfInterestSettings'
 * DelayTime; >= 0; will stop the POI for the pause time, and then return back 
*/
UFUNCTION(Category = "PointOfInterest", Meta = (AutoSplit = "PoiSettings"))
mixin void ApplyClampedPointOfInterest(AHazePlayerCharacter Player, FInstigator Instigator, 
	FHazePointOfInterestFocusTargetInfo FocusTarget, 
	FApplyClampPointOfInterestSettings PoiSettings,
	const FHazeCameraClampSettings&in PoiClamps, // We keep this as a ref to force the use of clamps in BP
	float BlendInTime = 2,
	EHazeCameraPriority Priority = EHazeCameraPriority::Low)
{
	auto POI = Player.CreatePointOfInterestClamped();
	POI.FocusTarget = FocusTarget;
	POI.Settings = PoiSettings;
	POI.Clamps = PoiClamps;
	POI.Apply(Instigator, BlendInTime, Priority);
}
