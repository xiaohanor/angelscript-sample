UCLASS(Abstract)
class USanctuaryBossSlideBlobEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode()
	{
	}


};	
class ASanctuaryBossSlideBlob : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BlobRoot;

	UPROPERTY(DefaultComponent, Attach = BlobRoot)
	UStaticMeshComponent BlobMesh;

	FVector InitialScale;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike GrowTimeLike;

	UPROPERTY(DefaultComponent, Attach = BlobRoot)
	UHazeMovablePlayerTriggerComponent PlayerTrigger;
	default PlayerTrigger.Shape = FHazeShapeSettings::MakeSphere(53.6);

	UPROPERTY(DefaultComponent)
	UHazeSphereComponent HazeSphere;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bActorIsVisualOnly = true;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	UPROPERTY(EditAnywhere)
	float GrowValue = 1.34;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrowTimeLike.BindUpdate(this, n"HandleTimeLikeUpdate");
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"HandleBeginOverlap");

		InitialScale = BlobRoot.RelativeScale3D;


		Timer::SetTimer(this, n"StartGrowing", Math::RandRange(0.1, 1.0));
		
	}


	UFUNCTION()
	private void StartGrowing()
	{
		GrowTimeLike.Play();
	}

	UFUNCTION()
	private void HandleBeginOverlap(AHazePlayerCharacter Player)
	{
		Player.DamagePlayerHealth(0.4);
		Explode();
	}

	void Explode()
	{
		/*for (auto Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) < 150)
				Player.DamagePlayerHealth(0.5);
		}*/

		BlobMesh.SetHiddenInGame(true);
		PlayerTrigger.DisableTrigger(this);
		USanctuaryBossSlideBlobEventHandler::Trigger_OnExplode(this);
		BP_Explode();
	
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode()
	{
	}

	UFUNCTION()
	private void HandleTimeLikeUpdate(float CurrentValue)
	{
		BlobRoot.SetRelativeScale3D(Math::Lerp(InitialScale, InitialScale * GrowValue, CurrentValue));
	}
};