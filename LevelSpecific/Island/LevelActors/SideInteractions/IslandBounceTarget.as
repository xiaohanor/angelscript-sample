event void FIslandBounceTargetEventSelfParam(AIslandBounceTarget Lock);

class AIslandBounceTarget : AHazeActor
{
	access ReadOnly = private, * (readonly);

	UPROPERTY()
	FIslandBounceTargetEventSelfParam OnActivated;

	UPROPERTY()
	FIslandBounceTargetEventSelfParam OnDeactivated;

	UPROPERTY()
	FIslandBounceTargetEventSelfParam OnCompleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent ShootMesh;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;

    UPROPERTY(DefaultComponent)
	USceneComponent ActivatedLocation;

	UPROPERTY(DefaultComponent)
	UIslandForceFieldStateComponent ForceFieldStateComp;
	default ForceFieldStateComp.bForceFieldIsOnEnemy = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY()
	UMaterialInterface ActiveMaterial;

	UPROPERTY()
	UMaterialInterface CompletedMaterial;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY(EditAnywhere)
	float TimeUntilReset = 3;

	UPROPERTY(EditAnywhere)
	FVector RelativeConnectedLineOffset = FVector(25.0, 0.0, 0.0);
	
	access:ReadOnly bool bFinishedAnimation;
	access:ReadOnly bool bActivated;
	access:ReadOnly bool bCompleted;
	access:ReadOnly bool bActivatedByGrenade;
	access:ReadOnly int ActivatedByGrenadeExplosionIndex;

	private float TimeUntilResetTimer;
	
	private TArray<AIslandBounceTarget> ConnectedLocks;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ShootMesh.SetMaterial(0, MioMaterial);
			ShootMesh.SetMaterial(0, MioMaterial);
		}
		else
		{
			ShootMesh.SetMaterial(0, ZoeMaterial);
			ShootMesh.SetMaterial(0, ZoeMaterial);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnDetonated");

		TimeUntilResetTimer = TimeUntilReset;

		if(UsableByPlayer == EHazePlayer::Mio)
		{
			GrenadeResponseComp.bTriggerForRedPlayer = true;
			GrenadeResponseComp.bTriggerForBluePlayer = false;
		}

		if(UsableByPlayer == EHazePlayer::Zoe)
		{
			GrenadeResponseComp.bTriggerForRedPlayer = false;
			GrenadeResponseComp.bTriggerForBluePlayer = true;
		}

	}

	UFUNCTION()
	private void OnDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		if(bActivated)
			return;

		if (Data.GrenadeOwner != Game::GetPlayer(UsableByPlayer))
			return;

		if(bCompleted)
			return;

		bActivatedByGrenade = true;
		ActivatedByGrenadeExplosionIndex = Data.ExplosionIndex;
		ActivateLock();
	}

	void ActivateLock()
	{
		if(bActivated)
			return;

		ShootMesh.SetMaterial(0, CompletedMaterial);
		BP_OnActivated();
		OnActivated.Broadcast(this);
		bActivated = true;
	}

	void DeactivateLock()
	{

		bActivated = false;


		bCompleted = false;
		bActivatedByGrenade = false;
		ConnectedLocks.Empty();
		TimeUntilResetTimer = TimeUntilReset;
		BP_OnDeactivated();
		OnDeactivated.Broadcast(this);
	}

	void SetCompleted()
	{
		bCompleted = true;
		ShootMesh.SetMaterial(1, CompletedMaterial);
		ShootMesh.SetMaterial(3, CompletedMaterial);
		BP_OnCompleted();
		OnCompleted.Broadcast(this);
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_OnCompleted() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated() {}

}