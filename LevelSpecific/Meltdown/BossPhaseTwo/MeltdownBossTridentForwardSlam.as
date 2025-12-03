class AMeltdownBossTridentForwardSlam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ShockwaveMesh;

	float StartScaleX;
	float StartScaleY;
	UPROPERTY()
	float EndScaleX;
	UPROPERTY()
	float EndScaleY;

	bool bDestroyOnFinished = true;

	UPROPERTY()
	float KillHeight = 50;
	UPROPERTY()
	float KillWidth = 100;

	FHazeTimeLike ShockwaveAnim;
	default ShockwaveAnim.Duration = 3.0;
	default ShockwaveAnim.UseLinearCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDamageEffect> TridentShockwaveDamage;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartScaleX = ShockwaveMesh.RelativeScale3D.X;
		StartScaleY = ShockwaveMesh.RelativeScale3D.Y;

		ShockwaveAnim.BindFinished(this, n"ShockwaveDone");
		ShockwaveAnim.BindUpdate(this, n"ShockwaveUpdate");

		ShockwaveAnim.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float CurrentRadius = ShockwaveMesh.GetWorldScale().Max * 437.5;

		for (auto Player : Game::Players)
		{
			float DistanceToCenter = Player.ActorLocation.Dist2D(ActorLocation, ActorUpVector);
			float CapsuleRadius = Player.CapsuleComponent.ScaledCapsuleRadius;
			if (DistanceToCenter + CapsuleRadius > CurrentRadius - (KillWidth * ShockwaveMesh.WorldScale.AbsMax)
				&& DistanceToCenter - CapsuleRadius < CurrentRadius )
			{
				float HeightDistance = ActorTransform.InverseTransformPositionNoScale(Player.CapsuleComponent.WorldLocation).Z + KillHeight;
				float CapsuleHeight = Player.CapsuleComponent.ScaledCapsuleHalfHeight;
				if (HeightDistance >= -CapsuleHeight && HeightDistance <= CapsuleHeight)
				{
					FVector KnockDirection = (Player.ActorLocation - ActorLocation).GetSafeNormal2D();
					Player.AddKnockbackImpulse(
						 KnockDirection, 900, 1200
					);
					Player.DamagePlayerHealth(0.5, DamageEffect = TridentShockwaveDamage);
				}
			}
		}
	}

	UFUNCTION()
	private void ShockwaveUpdate(float CurrentValue)
	{
		ShockwaveMesh.SetRelativeScale3D(Math::Lerp(FVector(StartScaleX,StartScaleY,0.5), FVector(EndScaleX,EndScaleY,0.5), CurrentValue));
	}

	UFUNCTION()
	private void ShockwaveDone()
	{

		if (bDestroyOnFinished)
			DestroyActor();
		else
			AddActorDisable(this);
	}

};