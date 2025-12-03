UCLASS(Abstract)
class USanctuarySpiritUrnEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPushed()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBroken()
	{
	}

};	
class ASanctuarySpiritUrn : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent AddImpulseCollider;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent UrnMesh;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BreakVFX;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbedPosition;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent FX_Spline;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX_SplineGhost;
	default FX_SplineGhost.SetAutoActivate(false);

	UPROPERTY(EditInstanceOnly)
	float MaxCullingDistMultiplier = 1.0;

	UPROPERTY(EditInstanceOnly)
	bool bCanTriggerVO = false;

	bool bGotPushed = false;
	bool bMoved = false;
	float Gravity = -980.0 * 2.0;
	FVector PendingImpulse;
	bool bSentBreak = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{	
		if (UrnMesh != nullptr)
		{
			UrnMesh.SetCullDistance(Editor::GetDefaultCullingDistance(UrnMesh) * MaxCullingDistMultiplier);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddImpulseCollider.OnComponentBeginOverlap.AddUFunction(this, n"PlayerOverlap");
		Movement = MoveComp.SetupSweepingMovementData();
		FVector SplineLocation = FX_Spline.GetWorldLocation();
		FQuat Rot = FQuat(FVector::UpVector, Math::RandRange(0.0, 6.0));
		FX_Spline.SetAbsolute(true, true, true);
		FX_Spline.SetWorldLocation(SplineLocation);
		FX_Spline.SetWorldRotation(Rot);
		
	}

	UFUNCTION(CrumbFunction)
	private void CrumbBreakRemoteAndRemove()
	{
		if (UrnMesh.IsVisible())
		{
			Break();
		}
		SetAutoDestroyWhenFinished(true);
	}

	private void Break()
	{
		USanctuarySpiritUrnEventHandler::Trigger_OnBroken(this);

		// Should it trigger potential VO.
		if (bCanTriggerVO)
		{
			// Player data isn't sent through, so guess who did it.
			// Fix this if deemed needed.
			auto ClosestPlayer = Game::GetClosestPlayer(ActorLocation);
			if (ClosestPlayer.GetDistanceTo(this) < 200)
				USanctuarySpiritUrnEventHandler::Trigger_OnBroken(ClosestPlayer);
		}

		Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakVFX, ActorLocation, ActorRotation);
		FX_Spline.SetAbsolute(true, true, true);
		FX_Spline.SetWorldLocation(ActorLocation);
		FX_SplineGhost.Activate(true);
		UrnMesh.SetVisibility(false);
	}

	UFUNCTION()
	private void PlayerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Playering = Cast<AHazePlayerCharacter>(OtherActor);
		if (Playering == nullptr)
			return;
		if (!Playering.HasControl())
			return;
		if (Playering.IsPlayerDead())
			return;
		if (Playering.IsActorBeingDestroyed())
			return;
		if (bGotPushed)
			return;
		bGotPushed = true;
		UHazeMovementComponent PlayerMoveComp = UHazeMovementComponent::Get(Playering);
		NetPush(PlayerMoveComp.Velocity * 1.0);
	}

	UFUNCTION(NetFunction)
	private void NetPush(FVector Impulse)
	{
		if (bMoved) // already got pushed by other player
			return;
		bGotPushed = true;
		PendingImpulse = Impulse;
		PendingImpulse.Z = 100.0;

		if (AttachParentActor != nullptr)
			DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		AddImpulseCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		bMoved = true;

		USanctuarySpiritUrnEventHandler::Trigger_OnPushed(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bMoved)
			return;
		
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if (bSentBreak)
				{
					Movement.AddDelta(FVector());
				}
				else
				{
					FVector Velocity = MoveComp.Velocity;
					FVector Acceleration = (FVector::UpVector * Gravity) - MoveComp.Velocity;
					Velocity += Acceleration * DeltaSeconds + ConsumeImpulse();

					FVector DeltaMove = Velocity * DeltaSeconds;
					Movement.SetRotation(DeltaMove.ToOrientationQuat());
					Movement.AddDelta(DeltaMove);
				}

				if (GetImpact().bBlockingHit && !bSentBreak)
				{
					bSentBreak = true;
					Break();
					CrumbBreakRemoteAndRemove();
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}

	FVector ConsumeImpulse()
	{
		FVector Impulse = PendingImpulse;
		PendingImpulse = FVector::ZeroVector;
		return Impulse;
	}

	FHitResult GetImpact()
	{
		FHitResult HitResult;

		if (MoveComp.HasGroundContact())
			HitResult = MoveComp.GroundContact.ConvertToHitResult();

		if (MoveComp.HasWallContact())
			HitResult = MoveComp.WallContact.ConvertToHitResult();

		if (MoveComp.HasCeilingContact())
			HitResult = MoveComp.CeilingContact.ConvertToHitResult();

		return HitResult;
	}
};