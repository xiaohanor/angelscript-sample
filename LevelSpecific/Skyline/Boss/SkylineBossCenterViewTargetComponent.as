enum ESkylineBossCenterViewTarget
{
	Head,
	Body,
	Feet
};

class USkylineBossCenterViewTargetComponent : UCenterViewTargetComponent
{
	default bAbsoluteLocation = true;

	UPROPERTY(EditDefaultsOnly, Category = "Tripod Boss")
	bool bDeactivateIfTooClose = false;

	UPROPERTY(EditDefaultsOnly, Category = "Tripod Boss", Meta = (EditCondition = "bDeactivateIfTooClose"))
	float DeactivateDistance = 5000;

	ASkylineBoss TripodBoss;

	ESkylineBossCenterViewTarget PreviousViewTarget = ESkylineBossCenterViewTarget::Head;
	FHazeAcceleratedVector AccOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		TripodBoss = Cast<ASkylineBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const ESkylineBossCenterViewTarget NewViewTarget = GetCenterViewTarget();
		const FVector TargetLocation = GetWantedLocation(NewViewTarget);

		if(PreviousViewTarget != NewViewTarget)
			AccOffset.SnapTo(WorldLocation - TargetLocation);

		AccOffset.AccelerateTo(FVector::ZeroVector, 4, DeltaSeconds);

		SetWorldLocation(TargetLocation + AccOffset.Value);

		PreviousViewTarget = NewViewTarget;
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(TripodBoss.IsStateActive(ESkylineBossState::Dead))
			return false;

		if(bDeactivateIfTooClose && Query.Player.ActorLocation.Dist2D(WorldLocation) < DeactivateDistance)
			return false;

		return true;
	}

	ESkylineBossCenterViewTarget GetCenterViewTarget() const
	{
		switch(TripodBoss.GetState())
		{
			case ESkylineBossState::Assemble:
				return ESkylineBossCenterViewTarget::Body;
			case ESkylineBossState::None:
				return ESkylineBossCenterViewTarget::Body;
			case ESkylineBossState::Combat:
				return ESkylineBossCenterViewTarget::Feet;
			case ESkylineBossState::PendingDown:
				return ESkylineBossCenterViewTarget::Body;
			case ESkylineBossState::Fall:
				return ESkylineBossCenterViewTarget::Body;
			case ESkylineBossState::Down:
				return ESkylineBossCenterViewTarget::Head;
			case ESkylineBossState::Rise:
				return ESkylineBossCenterViewTarget::Body;
			case ESkylineBossState::Dead:
				return ESkylineBossCenterViewTarget::Body;
		}
	}

	FVector GetWantedLocation(ESkylineBossCenterViewTarget CenterViewTarget) const
	{
		switch(CenterViewTarget)
		{
			case ESkylineBossCenterViewTarget::Head:
			{
				return TripodBoss.CoreCollision.WorldLocation;
			}
			case ESkylineBossCenterViewTarget::Body:
			{
				FVector AverageLocation = FVector::ZeroVector;

				for(int i = 0; i < int(ESkylineBossLeg::MAX); i++)
				{
					ESkylineBossLeg Leg = ESkylineBossLeg(i);
					AverageLocation += TripodBoss.GetFootTransform(Leg).Location;
				}

				AverageLocation += TripodBoss.CoreCollision.WorldLocation;

				AverageLocation /= int(ESkylineBossLeg::MAX) + 1;

				return AverageLocation;
			}
			case ESkylineBossCenterViewTarget::Feet:
			{
				FVector AverageLocation = FVector::ZeroVector;

				for(int i = 0; i < int(ESkylineBossLeg::MAX); i++)
				{
					ESkylineBossLeg Leg = ESkylineBossLeg(i);
					AverageLocation += TripodBoss.GetFootTransform(Leg).Location;
				}

				AverageLocation /= int(ESkylineBossLeg::MAX);

				return AverageLocation;
			}
		}
	}
};

#if EDITOR
class USkylineBossCenterViewTargetComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineBossCenterViewTargetComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto CenterViewTargetComp = Cast<USkylineBossCenterViewTargetComponent>(Component);
		if(CenterViewTargetComp == nullptr)
			return;

		DrawWireSphere(CenterViewTargetComp.WorldLocation, CenterViewTargetComp.DeactivateDistance, FLinearColor::Red, 10);
	}
}
#endif