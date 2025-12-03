class UStormDragonTornadoRendererComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UStormDragonTornadoRendererDud;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
	{
		UStormDragonTornadoRendererDud Comp = Cast<UStormDragonTornadoRendererDud>(Component);

		if (Comp == nullptr)
			return;
		
		AStormDragonTornado Tornado = Cast<AStormDragonTornado>(Comp.Owner);

		if (Tornado == nullptr)
			return;
		
		SetRenderForeground(false);
		DrawWireSphere(Tornado.ActorLocation + FVector::UpVector * 12000.0, Tornado.DamageRadius, FLinearColor::Red, 50.0, 16); 
	}
}

class UStormDragonTornadoRendererDud : USceneComponent
{

}

class AStormDragonTornado : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LargeDebrisRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LargeSlowDebrisRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SmallDebrisRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TornadoMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VortextEffect;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonTornadoCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonTornadoThrowObjectCapability");

	UPROPERTY(DefaultComponent)
	UStormDragonTornadoRendererDud Dud;

	UPROPERTY(DefaultComponent)
	UAdultDragonTakeDamageKillComponent DragonKillResponseComp;

	UPROPERTY(DefaultComponent)
	UAdultDragonTakeDamageDestructibleRocksComponent DestructibleRocksComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere, Category = "ThrowObject")
	ASplineActor ThrowObjectSpline;

	UPROPERTY(EditAnywhere, Category = "ThrowObject")
	AHazeActor ThowObject;

	UPROPERTY(EditAnywhere, Category = "ThrowObject")
	EHazeSelectPlayer TargetPlayer;

	UPROPERTY(EditAnywhere)
	float SplineSpeed = 800.0;

	UPROPERTY(EditAnywhere)
	float DamageRadius = 4000.0;
	float Damage = 0.3;

	UPROPERTY(EditAnywhere)
	float LargeRotationSpeed = 25.0;

	UPROPERTY(EditAnywhere)
	float SmallRotationSpeed = 35.0;

	UPROPERTY(EditAnywhere)
	int Direction = 1;

	UPROPERTY(EditAnywhere)
	bool bStartActive = true;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	FVector StartScale;

	bool bTornadoActive = true;
	bool bThrowObject;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bTornadoActive = bStartActive;

		DestructibleRocksComp.OnDestructibleRockHit.AddUFunction(this, n"OnDestructibleRockHit");

		// StartScale = ActorScale3D;
		// ActorScale3D = FVector(0.000001);

		// SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnDestructibleRockHit(USceneComponent HitComponent, AHazePlayerCharacter Player)
	{
		HitComponent.DestroyComponent(this);
		Player.DamagePlayerHealth(0.1);
	}

	UFUNCTION()
	void ActivateTornado()
	{
		bTornadoActive = true;
	}

	UFUNCTION()
	void ActivateTornadoThrow()
	{
		bThrowObject = true;
	}
}