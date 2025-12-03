struct FSkylineBouncyMushroomEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;

	FSkylineBouncyMushroomEventData(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
}

UCLASS(Abstract)
class UInnerCityGiantsBounceMushroomventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounce(FSkylineBouncyMushroomEventData Data)
	{
	}

};	

class AInnerCityGiantsBounceMushroom : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float Bounce = 1000;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent CallbackComp;

	UPROPERTY(DefaultComponent)
	USceneComponent VisualRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent CollisionRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ScaleTimeLike;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FF;

	private FVector InitialRelativeScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRelativeScale = VisualRoot.GetRelativeScale3D();

		CallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandlePlayerGroundImpact");
		ScaleTimeLike.BindUpdate(this, n"ScaleTimeLikeUpdated");
	}

	UFUNCTION()
	private void HandlePlayerGroundImpact(AHazePlayerCharacter Player)
	{
		
		ScaleTimeLike.PlayFromStart();
		Player.AddMovementImpulse(Player.GetMovementWorldUp() * Bounce);
		Player.PlayForceFeedback(FF, this, 1.0);
		UInnerCityGiantsBounceMushroomventHandler::Trigger_OnBounce(this,FSkylineBouncyMushroomEventData(Player));
	}

	UFUNCTION()
	private void ScaleTimeLikeUpdated(float CurrentValue)
	{
		float ScaleX = InitialRelativeScale.X * CurrentValue;
		float ScaleY = InitialRelativeScale.Y * CurrentValue;
		float ScaleZ = InitialRelativeScale.Z / CurrentValue;
		VisualRoot.SetRelativeScale3D(FVector(ScaleX, ScaleY, ScaleZ));
	}
};