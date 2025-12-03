event void FOnDoorBroken();

class AMeltdownScreenWalkJumpDoor : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Door;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ResponseTarget;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UPROPERTY()
	FOnDoorBroken DoorBroken;
	


	UFUNCTION(BlueprintCallable)
	void BreakDoor()
	{
		UScreenwalkJumpDoorEffectHandler::Trigger_DoorBreak(this, FMeltdownScreenWalkDoorBreaking(ResponseTarget));
		AddActorDisable(this);
		DoorBroken.Broadcast();
	}
};
