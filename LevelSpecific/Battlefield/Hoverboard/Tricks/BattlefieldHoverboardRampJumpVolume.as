class ABattlefieldHoverboardRampJumpVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	float RampJumpImpulse = BattlefieldHoverboardVolumeJumpSettings::JumpVolumeImpulse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerExit");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		if(TrickComp == nullptr)
			return;

		TrickComp.JumpVolumesInsideOf.AddUnique(this);
	}

	UFUNCTION()
	private void OnPlayerExit(AHazePlayerCharacter Player)
	{
		auto TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		if(TrickComp == nullptr)
			return;

		TrickComp.JumpVolumesInsideOf.RemoveSingleSwap(this);
	}
}