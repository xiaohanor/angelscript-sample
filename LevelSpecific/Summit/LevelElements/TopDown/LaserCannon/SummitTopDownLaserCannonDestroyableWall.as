event void FASummitTopDownLaserCannonDestroyableWallSignature();

class ASummitTopDownLaserCannonDestroyableWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> CameraShake;

	bool bIsDestroyed = false;

	UPROPERTY()
	FASummitTopDownLaserCannonDestroyableWallSignature OnWallDestruction;

	void GetDestroyed()
	{
		if(bIsDestroyed)
			return;

		MeshComp.AddComponentVisualsAndCollisionAndTickBlockers(this);
		for(auto Player : Game::Players)
		{
			Player.PlayCameraShake(CameraShake, this);
		}

		USummitTopDownLaserCannonDestroyableWallEventHandler::Trigger_OnDestroyed(this);

		bIsDestroyed = true;
		OnWallDestruction.Broadcast();
		BP_OnDestroyed();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnDestroyed()
	{}
};