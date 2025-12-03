struct FGravityBladeGrappleEjectSlowAimDeactivationParams
{
	bool bNormal = false;
}
class UGravityBladeGrappleEjectSlowAimCapability : UHazeChildCapability
{
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleEject);
	default BlockExclusionTags.Add(GravityBladeGrappleTags::GravityBladeGrappleEject);

	default DebugCategory = GravityBlade::DebugCategory;

	AHazePlayerCharacter Player;
	UGravityBladeGrappleUserComponent GrappleComp;
	UGravityBladeGrappleEjectComponent EjectComp;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData MoveData;

	float ActivateTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);

		MoveComp = UPlayerMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupSweepingMovementData();
		EjectComp = UGravityBladeGrappleEjectComponent::GetOrCreate(Owner);
	} 

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBladeGrappleEjectSlowAimDeactivationParams& Params) const
	{
		if(ActualActiveDuration > EjectComp.EjectData.SlowAimDuration)
		{
			Params.bNormal = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.SetActorTimeDilation(EjectComp.EjectData.TimeDilation, GravityBladeGrapple::Eject::Instigator);
		UMovementGravitySettings::SetGravityScale(Player, EjectComp.EjectData.GravityScale, this);
		ActivateTime = Time::GameTimeSeconds;

		Player.BlockCapabilities(PlayerMovementTags::AirMotion, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBladeGrappleEjectSlowAimDeactivationParams Params)
	{
		if (Params.bNormal)
			Player.SetActorTimeDilation(EjectComp.EjectData.TimeDilation, GravityBladeGrapple::Eject::Instigator);
		Player.StopSlotAnimationByAsset(GrappleComp.GrappleEjectAnimation);
		UMovementGravitySettings::ClearGravityScale(Player,this);
		Player.ClearCameraSettingsByInstigator(GravityBladeGrapple::Eject::Instigator);

		Player.UnblockCapabilities(PlayerMovementTags::AirMotion, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(MoveData))
		{
			MoveData.AddOwnerVerticalVelocity();
			MoveData.AddGravityAcceleration();
			MoveComp.ApplyMove(MoveData);
		}
	}

	float GetActualActiveDuration() const property
	{
		return Time::GameTimeSeconds - ActivateTime;
	}
}