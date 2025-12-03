
class ABabyDragonTailClimbPoint : AHazeActor
{
	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UBabyDragonTailClimbTargetable EnterTargetable;

	UPROPERTY(DefaultComponent, Attach = EnterTargetable)
	UArrowComponent WallNormal;
	default WallNormal.SetRelativeRotation(FRotator(180.0, 0.0, 0.0));

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	// Whether to trace 
	UPROPERTY(EditAnywhere, Category = "Climb Point")
	bool bTraceForWall = true;

	UFUNCTION()
	void TeleportPlayerIntoClimbing(AHazePlayerCharacter Player)
	{
		CrumbTeleportIntoClimb(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTeleportIntoClimb(AHazePlayerCharacter Player)
	{
		auto DragonComp = UPlayerTailBabyDragonComponent::Get(Player);
		if (DragonComp == nullptr)
			return;

		DragonComp.ClimbState = ETailBabyDragonClimbState::Enter;
		DragonComp.ClimbActivePoint = EnterTargetable;
		DragonComp.bClimbReachedPoint = true;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		if (!Editor::IsCooking() && Level.IsVisible() && Editor::IsSelected(this) && bTraceForWall)
		{
			FHitResult BestHit;
			float BestHitDistance = MAX_flt;

			FHazeTraceSettings Trace;
			Trace.UseLine();
			Trace.TraceWithChannel(ECollisionChannel::ECC_Visibility);

			float Phi = PI * (3.0 - Math::Sqrt(5.0));

			for (int Index = 0, Count = 300; Index < Count; ++Index)
			{
				FVector Direction;
				Direction.X = 1.0 - (float(Index) / float(Count)) * 2.0;

				float Radius = Math::Sqrt(1.0 - Math::Square(Direction.X * Direction.X));
				float Theta = Phi * float(Index);

				Direction.Y = Math::Cos(Theta) * Radius;
				Direction.Z = Math::Sin(Theta) * Radius;

				FHitResult Hit = Trace.QueryTraceSingle(
					ActorLocation - Direction * 10.0, ActorLocation + Direction * 50.0,
				);
				if (!Hit.bBlockingHit)
					continue;

				float Dist = Hit.ImpactPoint.Distance(ActorLocation);
				if (Dist < BestHitDistance)
				{
					BestHit = Hit;
					BestHitDistance = Dist;
				}
			}

			if (BestHit.bBlockingHit)
			{
				EnterTargetable.SetWorldLocationAndRotation(
					BestHit.ImpactPoint, FRotator::MakeFromXZ(-BestHit.ImpactNormal, ActorUpVector),
				);
				WallNormal.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator(180.0, 0.0, 0.0));
			}
		}

		auto VisMesh = CreatePlayerEditorVisualizer(EnterTargetable, EHazePlayer::Zoe, FTransform(FVector(-49.0, 0.0, 0.0)));
		VisMesh.AnimationMode = EAnimationMode::AnimationSingleNode;
		VisMesh.AnimationData.AnimToPlay = Cast<UAnimationAsset>(Editor::LoadAsset(n"/Game/Animation/Assets/Characters/Zoe/Behaviour/Summit/BabyDragon/BS_Zoe_Climb_Mh.BS_Zoe_Climb_Mh"));
		VisMesh.RefreshEditorPose();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}
}

class UBabyDragonTailClimbTargetable : UTargetableComponent
{
	default TargetableCategory = n"SecondaryLevelAbility";

	UPROPERTY(EditAnywhere, Category = "Climb Point")
	float MaxRange = BabyDragonTailClimb::GrabPointRange;

	UPROPERTY(EditAnywhere, Category = "Climb Point")
	float VisibleRange = BabyDragonTailClimb::PointVisibleRange;

	UPROPERTY(EditAnywhere, Category = "Climb Point")
	bool bTransitionToLedgeGrab = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	FTransform GetHangTransform() const
	{
		FRotator HangRotation = WorldRotation;
		HangRotation.Roll = 0.0;
		return FTransform(
			HangRotation,
			WorldLocation + WorldRotation.ForwardVector * -49.0);
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyVisibleRange(Query, VisibleRange);
		Targetable::ApplyTargetableRange(Query, MaxRange);
		Targetable::ApplyVisualProgressFromRange(Query, VisibleRange, MaxRange);

		if (Query.DistanceToTargetable < 200.0 && bTransitionToLedgeGrab)
		{
			if (Query.Player.IsAnyCapabilityActive(n"LedgeGrab"))
				return false;
		}

		if (Query.Result.Score <= 0.0)
			return true;

		auto DragonComp = UPlayerTailBabyDragonComponent::Get(Query.Player);
		if (DragonComp.ClimbActivePoint == this)
			return false;

		if (DragonComp.ClimbState == ETailBabyDragonClimbState::None)
		{
			Targetable::ScoreCameraTargetingInteraction(Query);
		}
		else
		{
			FVector WantedDirection = Query.Player.ViewRotation.ForwardVector;
			FVector NeedDirection = (WorldLocation - Query.Player.ActorLocation).GetSafeNormal();

			if (WantedDirection.IsNearlyZero())
				WantedDirection = FVector::UpVector;

			float AngleNeeded = NeedDirection.GetAngleDegreesTo(WantedDirection);
			if (AngleNeeded > BabyDragonTailClimb::ClimbAllowTransferMaximumAngle)
				return false;

			Query.Result.Score *= Math::Pow((360.0 - AngleNeeded) / 360.0, 2.0);
		}

		return true;
	}
}