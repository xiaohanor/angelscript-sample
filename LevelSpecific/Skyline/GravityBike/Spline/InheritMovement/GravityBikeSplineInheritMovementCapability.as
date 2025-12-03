struct FGravityBikeSplineInheritMovementActivateParams
{
	UGravityBikeSplineInheritMovementComponent InheritComp;
	USceneComponent ImpactComponent;
}

class UGravityBikeSplineInheritMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeSpline::MovementTags::GravityBikeSplineMovement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;

	UGravityBikeSplineInheritMovementComponent InheritComponent;
	USceneComponent FollowedComponent;
	FQuat CurrentRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeSplineInheritMovementActivateParams& Params) const
	{
		if(MoveComp.HasGroundContact())
		{
			auto InheritComp = UGravityBikeSplineInheritMovementComponent::Get(MoveComp.GroundContact.Actor);
			if(InheritComp != nullptr)
			{
				if(InheritComp.EnterCondition == EGravityBikeSplineInheritMovementEnterCondition::OnGround)
				{
					Params.InheritComp = InheritComp;
					Params.ImpactComponent = MoveComp.GroundContact.Component;
					return true;
				}
			}
		}

		auto InheritMovementManager = GravityBikeSpline::GetInheritMovementManager();
		for(auto InheritComp : InheritMovementManager.EnterZones)
		{
			if(InheritComp.IsPointInside(GravityBike.ActorLocation))
			{
				Params.InheritComp = InheritComp;
				Params.ImpactComponent = InheritComp;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		switch(InheritComponent.ExitCondition)
		{
			case EGravityBikeSplineInheritMovementExitCondition::OnAir:
			{
				if(MoveComp.IsInAir())
					return true;

				break;
			}

			case EGravityBikeSplineInheritMovementExitCondition::OnExitZone:
			{
				if(!InheritComponent.IsPointInside(GravityBike.ActorLocation))
					return true;

				break;
			}

			case EGravityBikeSplineInheritMovementExitCondition::OnOtherGround:
			{
				if(MoveComp.HasGroundContact())
				{
					auto InheritComp = UGravityBikeSplineInheritMovementComponent::Get(MoveComp.GroundContact.Actor);
					if(InheritComp == nullptr)
						return true;
				}

				break;
			}

			case EGravityBikeSplineInheritMovementExitCondition::OnOtherGroundOrAir:
			{
				if(MoveComp.IsInAir())
					return true;

				if(MoveComp.HasGroundContact())
				{
					auto InheritComp = UGravityBikeSplineInheritMovementComponent::Get(MoveComp.GroundContact.Actor);
					if(InheritComp == nullptr)
						return true;
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineInheritMovementActivateParams Params)
	{
		InheritComponent = Params.InheritComp;
		StartFollowing(Params.ImpactComponent, InheritComponent.FollowType);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StopFollowing();
		InheritComponent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		GravityBike.LastInheritedComponentRotation = CurrentRotation;
		CurrentRotation = FollowedComponent.ComponentQuat;

		if(MoveComp.HasGroundContact())
		{
			auto InheritComp = UGravityBikeSplineInheritMovementComponent::Get(MoveComp.GroundContact.Actor);
			if(InheritComp != nullptr)
			{
				if(InheritComp.EnterCondition != EGravityBikeSplineInheritMovementEnterCondition::OnGround)
					return;

				if(InheritComp != InheritComponent)
					InheritComponent = InheritComp;
			}

			StartFollowing(MoveComp.GroundContact.Component, InheritComponent.FollowType);
		}
	}

	void StartFollowing(USceneComponent InImpactComp, EMovementFollowComponentType FollowType)
	{
		if(FollowedComponent != nullptr)
		{
			if(InImpactComp == FollowedComponent)
				return;

			MoveComp.UnFollowComponentMovement(this);
		}

		FollowedComponent = InImpactComp;
		MoveComp.FollowComponentMovement(FollowedComponent, this, FollowType, EInstigatePriority::High);
		
		CurrentRotation = FollowedComponent.ComponentQuat;
	}

	void StopFollowing()
	{
		FollowedComponent = nullptr;
		MoveComp.UnFollowComponentMovement(this);
	}
};