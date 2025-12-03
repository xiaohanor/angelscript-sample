class UDentistBossToolDrillShakePlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ADentistBoss Dentist;
	ADentistBossToolDrill Drill;
	UDentistBossTargetComponent TargetComp;
	UDentistToothPlayerComponent PlayerToothComp;

	UDentistBossSettings Settings;

	const FVector ShakeFrequency = FVector(49.0, 67.0, 12.0);
	const FVector ShakeMagnitude = FVector(-1.771347554, 1.358275, -0.751234);

	FVector StartOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Drill = TListedActors<ADentistBossToolDrill>().Single;
		Dentist = TListedActors<ADentistBoss>().Single;
		TargetComp = UDentistBossTargetComponent::Get(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Dentist == nullptr)
			return false;

		if(Settings == nullptr)
			return false;

		if(Drill == nullptr)
			return false;

		if(Drill.TargetedPlayer != Player)
			return false;

		if(!TargetComp.bIsDrilling)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Drill.TargetedPlayer != Player)
			return true;

		if(!TargetComp.bIsDrilling)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerToothComp = UDentistToothPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RootOffsetComponent.FreezeLocationAndLerpBackToParent(this, 0.05);
		Player.MeshOffsetComponent.ClearOffset(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(Dentist == nullptr)
			Dentist = TListedActors<ADentistBoss>().Single;

		if(Drill == nullptr)
			Drill = TListedActors<ADentistBossToolDrill>().Single;
		
		if(Dentist == nullptr)
			return;
			
		if(TargetComp == nullptr)
			TargetComp = UDentistBossTargetComponent::Get(Dentist);
		
		if(Settings == nullptr)
			Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ShakeAmountX = Math::Sin(ActiveDuration * ShakeFrequency.X) * ShakeMagnitude.X;
		float ShakeAmountY = Math::Sin(-ActiveDuration * ShakeFrequency.Y) * ShakeMagnitude.Y;
		float ShakeAmountZ = Math::Sin(ActiveDuration * ShakeFrequency.Z) * ShakeMagnitude.Z;
		FVector ShakeOffset = FVector(ShakeAmountX, ShakeAmountY, ShakeAmountZ);

		Player.MeshOffsetComponent.SnapToRelativeLocation(this, Player.CapsuleComponent, ShakeOffset);
	}
};