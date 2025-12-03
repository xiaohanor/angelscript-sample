asset GiantsSkydiveMagnetCapabilitySheet of UHazeCapabilitySheet
{
	Capabilities.Add(UGiantsSkydiveMagnetCapability);
}

class UGiantsSkydiveMagnetCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UGiantsSkydiveMagnetPlayerComponent MagnetComp;
	UPlayerMovementComponent MoveComp;
	UPlayerSkydiveComponent SkydiveComp;
	UPlayerWallRunComponent WallRunComp;
	AHazePlayerCharacter OwnerPlayer;

	AGiantsSkydiveMagnetPoint MagnetPoint;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		SkydiveComp = UPlayerSkydiveComponent::Get(Owner);
		WallRunComp = UPlayerWallRunComponent::Get(Owner);
		MagnetComp = UGiantsSkydiveMagnetPlayerComponent::GetOrCreate(Owner);
		OwnerPlayer = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Owner.HasControl())
			return false;
		if (!SkydiveComp.IsSkydiveActive())
			return false;
		if (MoveComp.HasGroundContact())
			return false;
		if (WallRunComp.HasActiveWallRun())
			return false;
		if (MagnetComp.MagnetPoint == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SkydiveComp.IsSkydiveActive())
			return true;
		if (MoveComp.HasGroundContact())
			return true;
		if (WallRunComp.HasActiveWallRun())
			return true;
		if (MagnetComp.MagnetPoint == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		OwnerPlayer.BlockCapabilities(PlayerSkydiveTags::SkydiveInput, this);
		MagnetPoint = MagnetComp.MagnetPoint;
		MagnetPoint.bDebugActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MagnetPoint.bDebugActive = false;
		OwnerPlayer.UnblockCapabilities(PlayerSkydiveTags::SkydiveInput, this);
		MagnetComp.MagnetPoint = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTemporalLog TempLog = TEMPORAL_LOG(MagnetComp);

		float Dist = MagnetPoint.ActorLocation.Dist2D(Owner.ActorLocation, FVector::UpVector);
		TempLog.Value("Dist", Dist);

		if(Dist > MagnetPoint.MaxDistanceForMagnet)
		{
			return;
		}

		FVector DirToPoint = (MagnetPoint.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		DirToPoint = DirToPoint.ConstrainToPlane(FVector::UpVector);

		// float DirPointForwardDot = DirToPoint.DotProduct(MagnetPoint.ActorForwardVector);
		// TempLog.Value("Dir to Point Dot Point Forward", DirPointForwardDot);

		// FVector MovementInput = MoveComp.MovementInput;
		// float InputDotPoint = MovementInput.DotProduct(DirToPoint);
		// const float MinimumMagnetFraction = 1.0;
		// float FractionOfInputNotTowardsPoint = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(1.0, MinimumMagnetFraction), InputDotPoint);
		
		// // Debug::DrawDebugString(Owner.ActorLocation, "DOT " + InputDotPoint);

		// TempLog
		// 	.Value("Input dot point", InputDotPoint)
		// 	.Value("Fraction Of Input Not Towards Point", FractionOfInputNotTowardsPoint)
		// ;

		FVector Impulse;

		FVector ToPlayer = Owner.ActorLocation - MagnetPoint.ActorLocation;
		float Force = Math::GetMappedRangeValueClamped(FVector2D(MagnetPoint.PlayerDistanceForMinForce, MagnetPoint.PlayerDistanceForMaxForce), 
													FVector2D(MagnetPoint.MagnetForceMin, MagnetPoint.MagnetForceMax), ToPlayer.Size());

		if (GiantsDevToggles::DebugDrawMagnetPoint.IsEnabled())
		{
			Debug::DrawDebugLine(MagnetPoint.ActorLocation, Owner.ActorLocation, OwnerPlayer.GetPlayerDebugColor());
			Debug::DrawDebugString(Owner.ActorLocation, "Dist " + ToPlayer.Size() + "\n\nForce: " + Force, OwnerPlayer.GetPlayerDebugColor(), 0.0, 3.0);
		}

		Impulse += DirToPoint * Force * DeltaTime; // FractionOfInputNotTowardsPoint *
		MoveComp.AddPendingImpulse(Impulse);

		TempLog.Value("Magnet Impulse", Impulse);
	}
};