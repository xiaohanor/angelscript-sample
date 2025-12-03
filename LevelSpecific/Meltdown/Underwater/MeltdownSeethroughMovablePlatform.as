class AMeltdownSeethroughMovablePlatform : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent OuterRoot;

	UPROPERTY(DefaultComponent, Attach = OuterRoot)
	UInteractionComponent GrabInteraction;
	default GrabInteraction.InteractionSheet = MeltdownSeethroughMovablePlatformSheet;
	default GrabInteraction.RelativeLocation = FVector(0.0, 0.0, 10.0);
	default GrabInteraction.UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(EditInstanceOnly)
	AMeltdownUnderwaterManager Manager;
	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector MovementRotationPivot = FVector(500.0, 0.0, 0.0);
	UPROPERTY(EditAnywhere)
	FVector ProjectOffset(0.0, 0.0, -100.0);
	UPROPERTY(EditAnywhere)
	FRotator InitialRotation;
	UPROPERTY(EditAnywhere)
	UAnimSequence PullAnimation;

	FVector RotationPivot;
	float RadiusAroundActor = 0.0;
	bool bIsMoving = false;
	bool bCanUseInteraction = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotationPivot = ActorTransform.TransformPosition(MovementRotationPivot);
		OuterRoot.DetachFromComponent();

		RadiusAroundActor = RotationPivot.Distance(ActorLocation);
		SetLocationOnSphere(RotationPivot + InitialRotation.ForwardVector * RadiusAroundActor - ProjectOffset);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateInteractionEnabled();
		if (bIsMoving)
			MovePlatformInWorldSpace();
		else
			MoveGrabInteractionInScreenSpace();
	}


	private void UpdateInteractionEnabled()
	{
		// If the inner player is too close to the sphere, don't allow moving the platform
		float Distance = Game::Mio.ActorLocation.Distance(RotationPivot);
		if (Distance > RadiusAroundActor - 200.0)
		{
			bCanUseInteraction = false;
			GrabInteraction.KickAnyPlayerOutOfInteraction();
			GrabInteraction.Disable(this);
		}
		else
		{
			bCanUseInteraction = true;
			GrabInteraction.Enable(this);
		}
	}

	private void MoveGrabInteractionInScreenSpace()
	{
		// Update the grab interaction so it's positioned correctly
		FVector OuterLocation;
		if (!Manager.ProjectSeethrough_InsideToOutside(ActorLocation, true, OuterLocation))
		{
			// If the platform isn't visible move the interaction point away
			OuterLocation = FVector(-50000.0, 0.0, 0.0);
		}

		OuterRoot.SetWorldLocation(OuterLocation);
	}

	private void MovePlatformInWorldSpace()
	{
		if (!bCanUseInteraction)
			return;

		FVector Origin;
		FVector Direction;
		Manager.ProjectSeethrough_OutsideToInside(Game::Zoe.ActorLocation, Origin, Direction);

		const FVector Diff = Origin - RotationPivot;
		const float	V = Direction.DotProduct(-Diff);
		const float	Disc = RadiusAroundActor * RadiusAroundActor - (Diff.DotProduct(Diff) - V * V);

		if (Disc >= 0.0)
		{
			bool bHasPoint = false;
			FVector Point;

			{
				float Time = V - Math::Sqrt(Disc);
				Point = Origin + Direction * Time - ProjectOffset;
				if (Time >= 200.0)
					bHasPoint = true;
			}

			if (!bHasPoint)
			{
				float Time = V + Math::Sqrt(Disc);
				Point = Origin + Direction * Time - ProjectOffset;
				if (Time >= 200.0)
					bHasPoint = true;
			}

			if (bHasPoint)
				SetLocationOnSphere(Point);
		}
	}

	private void SetLocationOnSphere(FVector LocationOnSphere)
	{
		FRotator Rotation = FRotator::MakeFromX(
			(LocationOnSphere - RotationPivot).GetSafeNormal(),
		);

		SetActorLocationAndRotation(LocationOnSphere, Rotation);
	}
}

asset MeltdownSeethroughMovablePlatformSheet of UHazeCapabilitySheet
{
	AddCapability(n"MeltdownSeethroughPlatformCapability");
	AddCapability(n"MeltdownSeethroughDragPlatformCapability");
	AddCapability(n"PlayerMovementOvalDirectionInputCapability");
	Blocks.Add(n"Movement");
	Blocks.Add(n"GameplayAction");
};

class UMeltdownSeethroughPlatformCapability : UInteractionCapability
{
	AMeltdownSeethroughMovablePlatform Platform;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		Platform = Cast<AMeltdownSeethroughMovablePlatform>(Params.Interaction.Owner);
		Platform.bIsMoving = true;

		Player.PlaySlotAnimation(
			Animation = Platform.PullAnimation,
			bLoop = true,
		);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.ActorHorizontalVelocity.Size() > 1.0)
			Player.SetSlotAnimationPlayRate(Platform.PullAnimation, 1.0);
		else
			Player.SetSlotAnimationPlayRate(Platform.PullAnimation, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Platform.bIsMoving = false;
		Player.StopSlotAnimation();
	}
};

class UMeltdownSeethroughDragPlatformCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{	
				FVector2D RawMoveInput2D = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
				FVector TargetDirection = Player.ViewRotation.RotateVector(FVector(
					0.0, RawMoveInput2D.Y, RawMoveInput2D.X,
				));

				float Speed = MoveComp.Velocity.Size();
				float TargetSpeed = TargetDirection.Size() * 250.0;

				if (TargetSpeed <= 1.0)
				{
					Speed = 0.0;
				}
				else
				{
					Speed = Math::FInterpConstantTo(Speed, TargetSpeed, DeltaTime, 1000.0);
				}

				Movement.AddVelocity(TargetDirection.GetSafeNormal() * Speed);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			FName AnimTag = n"Movement";
			if(MoveComp.WasFalling())
				AnimTag = n"Landing";
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}
};