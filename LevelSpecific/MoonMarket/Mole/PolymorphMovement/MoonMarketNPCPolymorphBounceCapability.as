class UMoonMarketNPCPolymorphBounceCapability : UMoonMarketNPCWalkCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::BeforeMovement;

	bool bJump = false;
	float StartJumpTime;
	float GroundContactTime = 0;

	UMoonMarketShapeshiftComponent ShapeshiftComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShapeshiftComp = UMoonMarketShapeshiftComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape == nullptr)
			return false;

		if(!PolymorphComp.ShapeshiftComp.ShapeData.bCanBounce)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape == nullptr)
			return true;

		if(bJump)
			return false;

		if(Super::ShouldDeactivate())
			return true;

		if(!PolymorphComp.ShapeshiftComp.ShapeData.bCanBounce)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		
		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape != nullptr)
		{
			if(PolymorphComp.ShapeshiftComp.ShapeData.bCanBounce)
				PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape.SetAnimBoolParam(n"InAir", false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (!bJump)
		{
			GroundContactTime += DeltaTime;

			if(GroundContactTime > 0.05)
			{
				if(PolymorphComp.ShapeshiftComp.ShapeshiftShape != nullptr)
				{
					UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnBounceOrJump(PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));
					UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnBounceOrJump(Owner, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));
					PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape.SetAnimTrigger(n"Bounce");
					PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape.SetAnimBoolParam(n"InAir", true);
				}
				bJump = true;
				StartJumpTime = Time::GameTimeSeconds;
			}
		}
		else
		{
			Super::TickActive(DeltaTime);
			GroundContactTime = 0;
			FVector Location = Owner.ActorLocation;
			ApplyJumpDelta(Location, DeltaTime);
			Owner.SetActorLocation(Location);
		}
	}

	void ApplyJumpDelta(FVector& NewLocation, float DeltaTime)
	{
		FVector TargetSplinePosition = NewLocation;
		NewLocation += FVector::UpVector * WalkComp.JumpCurve.GetFloatValue(Time::GetGameTimeSince(StartJumpTime)) * 90;

		if(NewLocation.Z <= TargetSplinePosition.Z)
		{
			NewLocation.Z = TargetSplinePosition.Z;

			if(PolymorphComp.ShapeshiftComp.ShapeshiftShape != nullptr)
				PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape.SetAnimBoolParam(n"InAir", false);

			bJump = false;
		}
	}
};