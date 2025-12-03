class USanctuaryDodgerHeightCapability : UHazeCapability
{
	UBasicAITargetingComponent TargetComp;
	UBasicAISettings Settings;
	USanctuaryDodgerSettings DodgerSettings;

	float OriginalChaseHeight;
	float OriginalStrafeHeight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetComp = UBasicAITargetingComponent::Get(Owner);
		Settings = UBasicAISettings::GetSettings(Owner);
		DodgerSettings = USanctuaryDodgerSettings::GetSettings(Owner);
		OriginalChaseHeight = Settings.FlyingChaseHeight;
		OriginalStrafeHeight = Settings.FlyingCircleStrafeHeight;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TargetComp.HasValidTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!TargetComp.HasValidTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Owner.ClearSettingsByInstigator(this);

		float Distance = TargetComp.Target.ActorLocation.Distance(FVector(Owner.ActorLocation.X, Owner.ActorLocation.Y, TargetComp.Target.ActorLocation.Z));

		float ChaseFactor = Distance / Settings.ChaseMinRange;
		UBasicAISettings::SetFlyingChaseHeight(Owner, OriginalChaseHeight * ChaseFactor * DodgerSettings.RangeHeightFactor, this);

		float StrafeFactor = Distance / Settings.CircleStrafeMinRange;
		UBasicAISettings::SetFlyingCircleStrafeHeight(Owner, OriginalStrafeHeight * StrafeFactor * DodgerSettings.RangeHeightFactor, this);
	}
}