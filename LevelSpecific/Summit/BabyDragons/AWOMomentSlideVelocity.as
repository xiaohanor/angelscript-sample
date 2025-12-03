
class AAWOMomentSlideVelocity : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintCallable)
	void AddVelocityToMioAtStartOfSlide(APlayerForceSlideVolume Volume)
	{
		FVector Velocity = Volume.SlideDirection.ForwardVector.ConstrainToPlane(Game::GetMio().ActorRightVector) * 1500;
		Game::GetMio().SetActorVelocity(Velocity);
		Game::GetMio().SnapToGround(true, 25);
	}

	UFUNCTION(BlueprintCallable)
	void AddVelocityToZoeAtEndOfAWOMoment()
	{
		Game::GetZoe().SetActorVelocity(FVector::DownVector * 700);
	}

	UFUNCTION(BlueprintCallable, BlueprintEvent)
	void StartAWOMomentSoundDef() {}

	UFUNCTION(BlueprintCallable)
	void TriggerEvent_MioSlideStart()
	{
		UAWOMomentEventHandler::Trigger_OnMioSlideStart(this);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerEvent_MioLandedOnPlatform()
	{
		UAWOMomentEventHandler::Trigger_OnMioLandOnPlatform(this);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerEvent_ZoeSlideStart()
	{
		UAWOMomentEventHandler::Trigger_OnZoeSlideStart(this);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerEvent_AWOMomentStart()
	{
		UAWOMomentEventHandler::Trigger_OnAWOMomentStart(this);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerEvent_AWOMomentTailDragonClimbAttach()
	{
		UAWOMomentEventHandler::Trigger_OnAWOMomentTailDragonClimbAttach(this);
	}
};