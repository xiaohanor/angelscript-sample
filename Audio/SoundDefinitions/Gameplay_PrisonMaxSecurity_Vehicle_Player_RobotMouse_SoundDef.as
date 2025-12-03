
UCLASS(Abstract)
class UGameplay_PrisonMaxSecurity_Vehicle_Player_RobotMouse_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Hacked(){}

	UFUNCTION(BlueprintEvent)
	void BiteCable(){}

	UFUNCTION(BlueprintEvent)
	void Fall(){}

	UFUNCTION(BlueprintEvent)
	void UnHacked(){}

	UFUNCTION(BlueprintEvent)
	void StartStruggling(){}

	UFUNCTION(BlueprintEvent)
	void StopStruggling(){}

	/* END OF AUTO-GENERATED CODE */

	ARemoteHackableRobotMouse RobotMouse;

UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		RobotMouse = Cast<ARemoteHackableRobotMouse>(HazeOwner);
		MoveComp = UHazeMovementComponent::Get(Game::Mio);
	}

	UFUNCTION(BlueprintPure)
	float GetValidStickInput()
	{
		if (!HazeOwner.HasControl())
			return 0;

		auto Input = MoveComp.GetMovementInput();
		float MoveInput = Math::Clamp(Input.Y + Input.X, -1.0, 1.0);
		if (RobotMouse.bForwardBlocked)
			MoveInput = Math::Clamp(MoveInput, -1.0, 0.0);

		return Math::Abs(MoveInput);
	}
}