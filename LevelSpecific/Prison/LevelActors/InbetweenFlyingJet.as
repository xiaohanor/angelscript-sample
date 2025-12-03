UCLASS(Abstract)
class AInbetweenFlyingJet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent PlayerNearbyTrigger;
	default PlayerNearbyTrigger.Shape.Type = EHazeShapeType::Box;
	default PlayerNearbyTrigger.Shape.BoxExtents = FVector(4000, 7000, 7000);

	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerNearbyTrigger.OnPlayerEnter.AddUFunction(this,n"OnPlayerNearby");
	}

	UFUNCTION()
	private void OnPlayerNearby(AHazePlayerCharacter Player)
	{
		Player.PlayForceFeedback(ForceFeedbackEffect,false,true,this,1);
		ShipFlyBy(Player);
	}

	UFUNCTION(BlueprintEvent)
	void ShipFlyBy(AHazePlayerCharacter Player)
	{

	}
};
