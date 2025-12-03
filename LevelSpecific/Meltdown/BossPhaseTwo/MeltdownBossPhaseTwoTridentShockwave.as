class AMeltdownBossPhaseTwoTridentShockwave : AHazeActor
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

	UPROPERTY()
	float KillHeight = 50;
	UPROPERTY()
	float KillWidth = 100;

	bool bDestroyOnFinished = false;

	UPROPERTY(EditDefaultsOnly)
	float RotationSpeed;

	FHazeTimeLike ShockwaveAnim;
	default ShockwaveAnim.Duration = 4.0;
	default ShockwaveAnim.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartScaleX = ShockwaveMesh.RelativeScale3D.X;
		StartScaleY = ShockwaveMesh.RelativeScale3D.Y;

		ShockwaveAnim.BindFinished(this, n"ShockwaveDone");
		ShockwaveAnim.BindUpdate(this, n"ShockwaveUpdate");

		ShockwaveAnim.PlayFromStart();
	}

	UFUNCTION()
	private void ShockwaveUpdate(float CurrentValue)
	{
		ShockwaveMesh.SetRelativeScale3D(Math::Lerp(FVector(StartScaleX,StartScaleY,1), FVector(EndScaleX,EndScaleY,1), CurrentValue));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float CurrentRadius = ShockwaveMesh.GetWorldScale().Max * 400;

		ShockwaveMesh.AddLocalRotation(FRotator(0,RotationSpeed,0) * DeltaSeconds);

		for (auto Player : Game::Players)
		{
			float DistanceToCenter = Player.ActorLocation.Dist2D(ActorLocation, ActorUpVector);
			float CapsuleRadius = Player.CapsuleComponent.ScaledCapsuleRadius;
			if (DistanceToCenter + CapsuleRadius > CurrentRadius - KillWidth
				&& DistanceToCenter - CapsuleRadius < CurrentRadius )
			{
				float HeightDistance = ActorTransform.InverseTransformPositionNoScale(Player.ActorLocation).Z;
				float CapsuleHeight = Player.CapsuleComponent.ScaledCapsuleHalfHeight * 2.0;
				if (HeightDistance + CapsuleHeight >= 0 && HeightDistance < KillHeight)
				{
					Player.DamagePlayerHealth(0.5);
				}
			}
		}
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
