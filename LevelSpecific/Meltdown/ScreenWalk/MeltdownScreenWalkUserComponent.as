class UMeltdownScreenWalkUserComponent : UActorComponent
{
	UPROPERTY()
	UAnimSequence TempAnimation;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect StompFF;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};