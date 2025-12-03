class UGravityBikeFreeHalfPipeSlowMotionCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipe);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeSlowMotion);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeHalfPipeComponent HalfPipeComp;

	AHazePlayerCharacter Player;
	UGravityBikeWeaponUserComponent WeaponComp;

	float Alpha = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		HalfPipeComp = UGravityBikeFreeHalfPipeComponent::Get(GravityBike);

		Player = GravityBike.GetDriver();
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Alpha = 0;
		GravityBike.SetActorTimeDilation(GetTimeDilation(), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.ClearActorTimeDilation(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ShouldBeSlowMotion())
		{
			Alpha = HalfPipeComp.GetJumpAlpha();
		}
		else
		{
			Alpha = Math::FInterpConstantTo(Alpha, 0, DeltaTime, 2);
		}

		GravityBike.SetActorTimeDilation(GetTimeDilation(), this);
	}

	float GetTimeDilation() const
	{
		return HalfPipeComp.Settings.TimeDilationCurve.GetFloatValue(Alpha);
	}

	bool ShouldBeSlowMotion() const
	{
		if(GravityBikeFree::HalfPipe::bNoSlowMoIfNoAmmo)
		{
			if(WeaponComp != nullptr)
			{
				// If we can't fire, start lerping away the slow motion
				if(!WeaponComp.HasChargeForEquippedWeapon())
					return false;
			}
		}

		return true;
	}
}