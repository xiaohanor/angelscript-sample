class AMeltdownBossPhaseThreeShockwave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ShockwaveMesh;

	FVector StartScale;
	UPROPERTY()
	FVector EndScale;

	UPROPERTY()
	float KillWidth = 100;

	AStaticMeshActor BossPhase3Floor;

	int shockwaveIndex;

	bool bDestroyOnFinished = false;
	FVector KnockbackImpulse;

	FHazeTimeLike ShockwaveAnim;
	default ShockwaveAnim.Duration = 2.0;
	default ShockwaveAnim.UseLinearCurveZeroToOne();
	default ShockwaveAnim.bCurveUseNormalizedTime = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartScale = ShockwaveMesh.RelativeScale3D;

		ShockwaveAnim.BindFinished(this, n"ShockwaveDone");
		ShockwaveAnim.BindUpdate(this, n"ShockwaveUpdate");

		ShockwaveAnim.PlayFromStart();
	}

	UFUNCTION()
	private void ShockwaveUpdate(float CurrentValue)
	{
		ShockwaveMesh.SetRelativeScale3D(Math::Lerp(StartScale, EndScale, CurrentValue));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float CurrentRadius = ShockwaveMesh.GetWorldScale().Max * 437.5;

		for (auto Player : Game::Players)
		{
			float DistanceToCenter = Player.ActorLocation.Dist2D(ActorLocation, ActorUpVector);
			float CapsuleRadius = Player.CapsuleComponent.ScaledCapsuleRadius;
			if (DistanceToCenter + CapsuleRadius > CurrentRadius - KillWidth
				&& DistanceToCenter - CapsuleRadius < CurrentRadius)
			{
				if (Player.IsOnWalkableGround())
				{
					FVector KnockDirection = (Player.ActorLocation - ActorLocation).GetSafeNormal2D();
					Player.AddKnockbackImpulse(KnockDirection, KnockbackImpulse.X, KnockbackImpulse.Z);
					Player.DamagePlayerHealth(0.5);
				}
			}
		}
		
		if(BossPhase3Floor != nullptr)
		{
			FVector Location = GetActorLocation();
 			BossPhase3Floor.StaticMeshComponent.SetColorParameterValueOnMaterials(FName("Point" + (shockwaveIndex % 4)), FLinearColor(Location.X, Location.Y, Location.Z, CurrentRadius));
		}

		// Debug::DrawDebugCircle(
		// 	ActorLocation,
		// 	ShockwaveMesh.GetWorldScale().Max * 400, 
		// 	LineColor = FLinearColor::Red,
		// 	Thickness = 10,
		// );

		// Debug::DrawDebugCircle(
		// 	ActorLocation + FVector(0, 0, KillHeight),
		// 	ShockwaveMesh.GetWorldScale().Max * 400, 
		// 	LineColor = FLinearColor::Red,
		// 	Thickness = 10,
		// );

		// Debug::DrawDebugCircle(
		// 	ActorLocation,
		// 	ShockwaveMesh.GetWorldScale().Max * 400 - KillWidth,
		// 	LineColor = FLinearColor::Red,
		// 	Thickness = 10,
		// );

		// Debug::DrawDebugCircle(
		// 	ActorLocation + FVector(0, 0, KillHeight),
		// 	ShockwaveMesh.GetWorldScale().Max * 400 - KillWidth, 
		// 	LineColor = FLinearColor::Red,
		// 	Thickness = 10,
		// );
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

namespace MeltdownBossPhaseThree
{
	AMeltdownBossPhaseThreeShockwave SpawnShockwave(TSubclassOf<AMeltdownBossPhaseThreeShockwave> Class, FVector Location, float MaxRadius = 4000, float Duration = 4.0, AStaticMeshActor BossPhase3Floor = nullptr, int shockwaveIndex = 0)
	{
		AMeltdownBossPhaseThreeShockwave Telegraph = SpawnActor(Class, Location, bDeferredSpawn = true);
		if (Telegraph == nullptr)
			return nullptr;
		Telegraph.shockwaveIndex = shockwaveIndex;
		Telegraph.BossPhase3Floor = BossPhase3Floor;
//		Telegraph.ShockwaveAnim.Duration = Duration;
		Telegraph.EndScale = FVector(MaxRadius / 400, MaxRadius / 400, 1);
		Telegraph.bDestroyOnFinished = true;
		FinishSpawningActor(Telegraph);
		return Telegraph;
	}
}