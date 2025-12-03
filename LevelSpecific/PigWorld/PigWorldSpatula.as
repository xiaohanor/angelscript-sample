UCLASS(Abstract)
class APigWorldSpatula : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent BounceMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent LaunchDirectionComp;

	UPROPERTY(DefaultComponent, Attach = BounceMeshComp)
	UBoxComponent OverlapComp;

	UPROPERTY(DefaultComponent, Attach = BounceMeshComp)
	UBoxComponent LaunchOverlapComp;

	UPROPERTY()
	UForceFeedbackEffect LaunchFF;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LaunchCameraShake;

	UPROPERTY(EditAnywhere)
	float LaunchSpeed = 1000; 


	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWrightComp;

	AHazePlayerCharacter LaunchPlayer;

	bool bReady = true;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"Impact");
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"MaxHit");
		RotateComp.OnMinConstraintHit.AddUFunction(this, n"MinHit");
	}

	UFUNCTION()
	private void MinHit(float Strength)
	{
		bReady = true;
	}

	UFUNCTION()
	private void MaxHit(float Strength)
	{
		if(LaunchPlayer != nullptr && bReady == true)
		{
			FVector Impulse = LaunchDirectionComp.ForwardVector*LaunchSpeed;
			Print(""+Strength);
			if(Strength > 1.5)
			{
				LaunchPlayer.AddActorWorldOffset(FVector(0,0,25));
				LaunchPlayer.ResetMovement();
				LaunchPlayer.AddMovementImpulse(Impulse);
				LaunchPlayer.PlayForceFeedback(LaunchFF,false,true,this,1);
				LaunchPlayer.PlayCameraShake(LaunchCameraShake,this,1);
				LaunchPlayer = nullptr;
			}
			bReady = false;
			UPigWorldSpatulaEventHandler::Trigger_OnLaunch(this);
		}
	}

	UFUNCTION()
		private void Impact(AHazePlayerCharacter Player)
	{
		if(OverlapComp.IsOverlappingActor(Player) && LaunchOverlapComp.IsOverlappingActor(Player.OtherPlayer))
		{
			RotateComp.ApplyImpulse(Player.GetActorLocation(), FVector(0,0,-250));
			LaunchPlayer = Player.OtherPlayer;
		}

	}



	UFUNCTION(BlueprintEvent)
	void OnImpact(AHazePlayerCharacter Player){}
};
