
enum ESquishTriggerBoxPolarity
{
	Down,
	Up,
	Left,
	Right,
	// Universal squish triggers squish when moving towards boxes of any polarity.
	Universal,
};

/**
 * A box component that kills the player as soon as the following conditions are met:
 * - The player overlaps two squish boxes with opposing polarity (Left-Right, Up-Down)
 * - Both the squish boxes overlapping the player also overlap each other.
 * - One of the trigger boxes is moving towards the other.
 */
class USquishTriggerBoxComponent : UBoxComponent
{
	// Whether the squish trigger is enabled and can kill the player right now
	UPROPERTY(EditAnywhere, Category = "Squish Trigger")
	bool bEnabled = true;

	// Only squish boxes with opposite polarity can kill the player
	UPROPERTY(EditAnywhere, Category = "Squish Trigger")
	ESquishTriggerBoxPolarity Polarity;

	UPROPERTY(EditAnywhere, Category = "Squish Trigger")
	TSubclassOf<UDeathEffect> DeathEffect;

	/**
	 * If set, the player will always be killed when overlapping two
	 * boxes of opposity polarity, regardless of whether they're moving
	 * towards each other or not.
	 */
	UPROPERTY(EditAnywhere, Category = "Squish Trigger")
	bool bIgnoreVelocityForKill = false;

	/**
	 * If set, only velocities similar to the specified direction are allowed to kill.
	 */
	UPROPERTY(EditAnywhere, Category = "Squish Trigger", Meta = (InlineEditConditionToggle))
	bool bConstrainKillVelocity = false;

	/**
	 * If set, only velocities similar to the specified direction are allowed to kill.
	 */
	UPROPERTY(EditAnywhere, Category = "Squish Trigger", Meta = (EditCondition = "bConstrainKillVelocity"))
	FVector KillVelocityConstraint(0.0, 0.0, -1.0);

	default SetCollisionProfileName(n"TriggerOnlyPlayer");
	default bDisableUpdateOverlapsOnComponentMove = true;

	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostPhysics;

	private TArray<AHazePlayerCharacter> OverlappingPlayers;
	private FVector PreviousPosition;
	private FRotator PreviousRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
        OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (DeltaTime <= 0.0)
			return;

		FVector VelocityDirection = (WorldLocation - PreviousPosition).GetSafeNormal();
		FRotator RotationVelocity = (WorldRotation - PreviousRotation) * (1.0 / DeltaTime);

		// Check if we should kill any of the players overlapping us
		if ((!VelocityDirection.IsNearlyZero() || !RotationVelocity.IsNearlyZero() || bIgnoreVelocityForKill) && bEnabled)
		{
			if (!bConstrainKillVelocity || VelocityDirection.DotProduct(WorldRotation.RotateVector(KillVelocityConstraint)) >= 0.8)
			{
				TArray<UPrimitiveComponent> Overlaps;
				for (auto Player : OverlappingPlayers)
				{
					if (Player.IsPlayerDead())
						continue;

					Overlaps.Reset();
					Player.CapsuleComponent.GetOverlappingComponents(Overlaps);

					for (auto OtherOverlap : Overlaps)
					{
						auto OtherSquish = Cast<USquishTriggerBoxComponent>(OtherOverlap);
						if (OtherSquish == nullptr)
							continue;
						if (OtherSquish == this)
							continue;
						if (!OtherSquish.bEnabled)
							continue;

						if (!IsOppositePolarity(Polarity, OtherSquish.Polarity))
							continue;

						// Kill the player if we are moving in the direction of the other box
						FVector ClosestPoint;
						float Distance = OtherSquish.GetClosestPointOnCollision(PreviousPosition, ClosestPoint);
						bool bMovingTowards = false;

						if (bIgnoreVelocityForKill)
						{
							bMovingTowards = true;
						}
						else if (Distance <= KINDA_SMALL_NUMBER)
						{
							// We are overlapping the other box, so we should check the
							// speed between the center points instead. This probably has some
							// edge cases if the second box center point extends 'below' the first one.
							FVector Direction = (OtherSquish.WorldLocation - PreviousPosition).GetSafeNormal();
							if (Direction.DotProduct(VelocityDirection) >= 0.1)
								bMovingTowards = true;
						}
						else
						{
							// We aren't inside the other box, so we can check the movement direction
							FVector Direction = (ClosestPoint - PreviousPosition).GetSafeNormal();
							if (Direction.DotProduct(VelocityDirection) >= 0.1)
								bMovingTowards = true;
						}

						if (bMovingTowards)
							Player.KillPlayer(DeathEffect = DeathEffect);
					}
				}
			}
		}

		PreviousPosition = WorldLocation;
		PreviousRotation = WorldRotation;

		if (OverlappingPlayers.Num() == 0)
			SetComponentTickEnabled(false);
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (OtherComponent != Player.CapsuleComponent)
			return;

		if (OverlappingPlayers.Num() == 0)
			PreviousPosition = WorldLocation;

		OverlappingPlayers.Add(Player);
		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (OtherComponent != Player.CapsuleComponent)
			return;

		OverlappingPlayers.Remove(Player);
	}

	bool IsOppositePolarity(ESquishTriggerBoxPolarity A, ESquishTriggerBoxPolarity B) const
	{
		if (A == ESquishTriggerBoxPolarity::Universal)
			return true;
		if (B == ESquishTriggerBoxPolarity::Universal)
			return true;
		if (A == ESquishTriggerBoxPolarity::Down && B == ESquishTriggerBoxPolarity::Up)
			return true;
		if (B == ESquishTriggerBoxPolarity::Down && A == ESquishTriggerBoxPolarity::Up)
			return true;
		if (A == ESquishTriggerBoxPolarity::Left && B == ESquishTriggerBoxPolarity::Right)
			return true;
		if (B == ESquishTriggerBoxPolarity::Left && A == ESquishTriggerBoxPolarity::Right)
			return true;
		return false;
	}
};

class ASquishTriggerBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USquishTriggerBoxComponent SquishTrigger;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;
};