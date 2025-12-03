class USkylineTorHammerStolenAttackCameraCapability : UHazeCapability
{	
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerStolenComponent StolenComp;
	USkylineTorDamageComponent TorDamageComp;
	ASkylineTor Tor;
	bool bActivate;
	FHazeAcceleratedVector AccLoc;
	FHazeAcceleratedRotator AccRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		StolenComp = USkylineTorHammerStolenComponent::GetOrCreate(Owner);

		Tor = TListedActors<ASkylineTor>().GetSingle();
		TorDamageComp = USkylineTorDamageComponent::Get(Tor);
		USkylineTorHammerResponseComponent::GetOrCreate(Tor).OnHit.AddUFunction(this, n"HammerHit");
	}

	UFUNCTION()
	private void HammerHit(float Damage, EDamageType DamageType, AHazeActor Instigator)
	{
		if(!TorDamageComp.bIsPerformingFinishingHammerBlow)
			return;
		bActivate = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(bActivate)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > StolenComp.FinalBlowCameraDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bActivate = false;
		Game::GetZoe().ActivateCamera(Tor.HammerBlowCamera, 1, this, EHazeCameraPriority::High);
		Tor.HammerBlowCamera.WorldLocation = GetCamLocation();
		Tor.HammerBlowCamera.WorldRotation = GetCamRotation();
		AccLoc.SnapTo(Tor.HammerBlowCamera.WorldLocation);
		AccRot.SnapTo(Tor.HammerBlowCamera.WorldRotation);

		StolenComp.PlayerStolenComp.Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		StolenComp.PlayerStolenComp.Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		StolenComp.PlayerStolenComp.Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		StolenComp.PlayerStolenComp.Player.BlockCapabilities(PlayerMovementTags::GroundJump, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Game::GetZoe().DeactivateCameraByInstigator(this, 1);
		StolenComp.PlayerStolenComp.Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		StolenComp.PlayerStolenComp.Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		StolenComp.PlayerStolenComp.Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		StolenComp.PlayerStolenComp.Player.UnblockCapabilities(PlayerMovementTags::GroundJump, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccLoc.AccelerateTo(GetCamLocation(), 0.5, DeltaTime);
		Tor.HammerBlowCamera.WorldLocation = AccLoc.Value;
		AccRot.AccelerateTo(GetCamRotation(), 0.5, DeltaTime);
		Tor.HammerBlowCamera.WorldRotation = AccRot.Value;
	}

	private FVector GetCamLocation()
	{
		FVector Direction = (Game::Zoe.ActorLocation - Tor.ActorLocation).GetSafeNormal();
		return Tor.ActorLocation + Direction * 600 + FVector::UpVector * 300;
	}

	private FRotator GetCamRotation()
	{
		return ((Tor.ActorLocation + FVector::UpVector * 250) - Tor.HammerBlowCamera.WorldLocation).Rotation();
	}	
}