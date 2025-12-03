// This capability exists because air dash capability consumes dash input (and hover perch input is linked to player input)
class UHoverPerchDashInputCapability : UHazeCapability
{
	default CapabilityTags.Add(HoverPerchBlockedWhileIn::Grind);

	default TickGroup = EHazeTickGroup::Input;

	AHoverPerchActor HoverPerch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverPerch = Cast<AHoverPerchActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(Time::GetGameTimeSince(HoverPerch.HoverPerchComp.TimeLastStoppedGrinding) < 1.0)
			return false;

		if(!WasActionStarted(ActionNames::MovementDash))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HoverPerch.FrameOfDashActionStarted.Set(Time::FrameNumber);
	}
}