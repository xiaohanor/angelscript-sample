class UTundraPlayerPutDownCrackBirdCapability : UTundraPlayerCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	const float PutDownDuration = 1.8333;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CarryComp.GetCurrentState() != ETundraPlayerCrackBirdState::PuttingDown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= PutDownDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		CarryComp.FinishPuttingDownBird();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > 0.3)
			TraceForOtherPlayer(DeltaTime);

		if(Player.Mesh.CanRequestLocomotion())
		{
			if(GetBird().bIsEgg)
			{
				Player.Mesh.RequestLocomotion(n"PickUpBirdEgg", this);
			}
			else
			{
				Player.Mesh.RequestLocomotion(n"PickUpBird", this);
			}
		}
	}

	void TraceForOtherPlayer(float DeltaTime)
	{
		FHazeTraceSettings TraceSettings = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
		TraceSettings.UseSphereShape(GetBird().Collision.SphereRadius * 0.7);
		TraceSettings.IgnoreActor(Player);

		const FVector Start = GetBird().ActorLocation;
		const FVector End = GetBird().ActorLocation + FVector::DownVector * 20;
		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);
		TraceSettings.DebugDrawOneFrame();

		if(Hit.bBlockingHit)
		{
			AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
			if(HitPlayer != nullptr)
			{
				auto ShapeType = UTundraPlayerShapeshiftingComponent::Get(HitPlayer).GetCurrentShapeType();
				if(ShapeType == ETundraShapeshiftShape::Big)
				{
					HitPlayer.AddMovementImpulse((HitPlayer.ActorLocation - Start).VectorPlaneProject(FVector::UpVector) * Hit.PenetrationDepth * DeltaTime);
				}
				else if(ActiveDuration < PutDownDuration - 0.5 && (HitPlayer.IsMio() || ShapeType != ETundraShapeshiftShape::Small))
				{
					HitPlayer.KillPlayer();
				}
			}
		}
	}
};