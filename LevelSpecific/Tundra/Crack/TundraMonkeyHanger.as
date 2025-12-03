UCLASS(Abstract)
class ATundraMonkeyHanger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UFauxPhysicsTranslateComponent PhysicsTranslateComponent;
	default PhysicsTranslateComponent.bConstrainX = true;
	default PhysicsTranslateComponent.bConstrainY = true;
	default PhysicsTranslateComponent.bConstrainZ = true;
	default PhysicsTranslateComponent.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent, Attach=PhysicsTranslateComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyCeilingClimbComponent CeilingComponent;

	UPROPERTY(DefaultComponent)
	UTundraMonkeyHangerVisualizerComponent VisualizerComp;

	/* These actors will be ignored when tracing up and down to figure out the z clamps for the physics translate component */
	UPROPERTY(EditAnywhere)
	TArray<AActor> IgnoredActors;

	UPROPERTY(EditAnywhere)
	float ForceToApplyWhenHanging = 2000.0;

	UPROPERTY(EditAnywhere)
	float SpringBackForce = 2000.0;

	UPROPERTY(EditAnywhere)
	bool bTraceToDetermineStopPoint = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bTraceToDetermineStopPoint", EditConditionHides))
	float StopPointDistance = 500.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bTraceToDetermineStopPoint", EditConditionHides))
	float MaxTraceLength = 10000.0;

	/* Add to this value if you are having issues with the monkey letting go of the ceiling, this is because the capsule penetrates the ground. */
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bTraceToDetermineStopPoint", EditConditionHides))
	float CapsuleHeightPadding = 50.0;

	UPROPERTY(EditAnywhere)
	bool bHangerShouldStayDown = true;

	private bool bAttached = false;
	private FHitResult LatestHitResult;
	private USceneComponent LatestDownTraceHitComponent;

	private float PreviousTranslateCompHeight = 0.0;
	float MonkeyHangerVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		if(HasControl())
		{
			CeilingComponent.OnAttach.AddUFunction(this, n"Attach");
			CeilingComponent.OnDeatch.AddUFunction(this, n"Detach");
		}
		else
		{
			SetActorTickEnabled(false);
		}

		PhysicsTranslateComponent.OnConstraintHit.AddUFunction(this, n"OnConstraintHit");

		if(!bTraceToDetermineStopPoint)
		{
			PhysicsTranslateComponent.MaxZ = 0.0;
			PhysicsTranslateComponent.MinZ = -StopPointDistance;
		}
	}

	UFUNCTION()
	private void OnConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		FTundraMonkeyHangerReachParams Params;
		Params.HitStrength = HitStrength;

		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Min) // Bottom
		{
			if(LatestDownTraceHitComponent == nullptr || LatestDownTraceHitComponent.Mobility == EComponentMobility::Static)
			{
				UTundraMonkeyHangerEffectHandler::Trigger_OnReachedBottomOnGround(this, Params);
			}
			else
			{
				UTundraMonkeyHangerEffectHandler::Trigger_OnReachedBottomOnFlower(this, Params);
			}
		}
		else if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Max) // Top
		{
			UTundraMonkeyHangerEffectHandler::Trigger_OnReachedTop(this, Params);
		}
	}

	UFUNCTION()
	private void Attach()
	{
		bAttached = true;
		UTundraMonkeyHangerEffectHandler::Trigger_OnStartHanging(this);
	}

	UFUNCTION()
	private void Detach()
	{
		if(!bHangerShouldStayDown)
			bAttached = false;
		UTundraMonkeyHangerEffectHandler::Trigger_OnStopHanging(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float CurrentHeight = PhysicsTranslateComponent.RelativeLocation.Z;
		MonkeyHangerVelocity = (CurrentHeight - PreviousTranslateCompHeight) / DeltaSeconds;
		PreviousTranslateCompHeight = CurrentHeight;

		AHazePlayerCharacter Player = Game::Mio;
		float Force = 0.0;

		if(bAttached)
			Force -= ForceToApplyWhenHanging;
		else
			Force += SpringBackForce;

		if(Math::IsNearlyZero(Force))
			return;

		if(bTraceToDetermineStopPoint)
		{
			FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(Mesh);
			Trace.IgnorePlayers();
			Trace.IgnoreActor(this);
			Trace.IgnoreActors(IgnoredActors);
			FHitResult Hit = Trace.QueryTraceSingle(Mesh.WorldLocation, Mesh.WorldLocation + FVector::UpVector * (Math::Sign(Force) * MaxTraceLength));
			
			float TraceDistance = Hit.Time * MaxTraceLength;
			float CapsuleHeight = Player.CapsuleComponent.CapsuleHalfHeight * 2 + CapsuleHeightPadding;
			if(Force > 0.0)
			{
				// Monkey hanger moving upwards
				if(!Hit.bBlockingHit || TraceDistance > Math::Abs(PhysicsTranslateComponent.RelativeLocation.Z))
					PhysicsTranslateComponent.MaxZ = 0.0;
				else
					PhysicsTranslateComponent.MaxZ = PhysicsTranslateComponent.RelativeLocation.Z + TraceDistance;
			}
			else
			{
				// Monkey hanger moving downwards
				LatestDownTraceHitComponent = Hit.Component;
				if(!Hit.bBlockingHit)
					PhysicsTranslateComponent.MinZ = -TraceDistance + Player.CapsuleComponent.CapsuleHalfHeight * 2;
				else
				{
					PhysicsTranslateComponent.MinZ = PhysicsTranslateComponent.RelativeLocation.Z - TraceDistance + CapsuleHeight;

					FVector PlayerOrigin = Player.ActorLocation - FVector::UpVector * (CapsuleHeightPadding * 0.5);
					FHazeTraceSettings PlayerTrace = Trace::InitFromPlayer(Player);
					PlayerTrace.UseCapsuleShape(Player.CapsuleComponent.CapsuleRadius, CapsuleHeight * 0.5);
					PlayerTrace.IgnorePlayers();
					PlayerTrace.IgnoreActor(this);
					FHitResult PlayerHit = PlayerTrace.QueryTraceSingle(PlayerOrigin, PlayerOrigin - FVector::UpVector * MaxTraceLength);

					if(PlayerHit.bBlockingHit)
					{
						LatestDownTraceHitComponent = PlayerHit.Component;
						float PlayerTraceDistance = PlayerHit.Time * MaxTraceLength;
						float ExtraOffset = Math::Max(0.0, PlayerTraceDistance - TraceDistance + CapsuleHeight);
						ExtraOffset = Math::Min(CapsuleHeight, ExtraOffset);

						PhysicsTranslateComponent.MinZ -= ExtraOffset;
					}
				}
			}
		}

		PhysicsTranslateComponent.ApplyForce(PhysicsTranslateComponent.WorldLocation, FVector::UpVector * Force);
	}
}


class UTundraMonkeyHangerVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

#if EDITOR
class UTundraMonkeyHangerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraMonkeyHangerVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto MonkeyHanger = Cast<ATundraMonkeyHanger>(Component.Owner);

		if(MonkeyHanger.bTraceToDetermineStopPoint)
			return;

		FVector2D MonkeyCapsuleSize = TundraShapeshiftingStatics::SnowMonkeyCollisionSize;
		FBox Bounds = MonkeyHanger.Mesh.GetComponentLocalBoundingBox();
		FVector UpVector = MonkeyHanger.PhysicsTranslateComponent.UpVector;
		FVector BoundsWorldOrigin = MonkeyHanger.Mesh.WorldTransform.TransformPosition(Bounds.Center) - UpVector * MonkeyHanger.StopPointDistance;
		FVector BoundsExtents = Bounds.Extent * MonkeyHanger.Mesh.WorldScale;
		DrawWireBox(BoundsWorldOrigin, BoundsExtents, MonkeyHanger.Mesh.ComponentQuat, FLinearColor::Red, 5.0);
		DrawWireCapsule(BoundsWorldOrigin - UpVector * (BoundsExtents.Z + MonkeyCapsuleSize.Y), FRotator(), FLinearColor::LucBlue, MonkeyCapsuleSize.X, MonkeyCapsuleSize.Y, 6, 5.0);
	}
}
#endif