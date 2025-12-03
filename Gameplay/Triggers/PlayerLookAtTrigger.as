
UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData Collision Replication Activation Physics")
class APlayerLookAtTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "PlayerLookAtTrigger";
	default Billboard.WorldScale3D = FVector(5.0); 
#endif	

	UPROPERTY(DefaultComponent, ShowOnActor)
	UPlayerLookAtTriggerComponent LookAtTrigger;

	UPROPERTY()
	FPlayerLookAtEvent OnBeginLookAt;

	UPROPERTY()
	FPlayerLookAtEvent OnEndLookAt;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LookAtTrigger.OnBeginLookAt.AddUFunction(this, n"BeginLookAt");
		LookAtTrigger.OnEndLookAt.AddUFunction(this, n"EndLookAt");
	}

	UFUNCTION(NotBlueprintCallable)
	void BeginLookAt(AHazePlayerCharacter Player)
	{
		OnBeginLookAt.Broadcast(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void EndLookAt(AHazePlayerCharacter Player)
	{
		OnEndLookAt.Broadcast(Player);
	}
}
