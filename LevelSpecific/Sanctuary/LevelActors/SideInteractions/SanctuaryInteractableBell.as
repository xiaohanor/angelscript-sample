UCLASS(Abstract)
class USanctuaryInteractableBellEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

};	
class ASanctuaryInteractableBell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent ConeRotate1;

	UPROPERTY(DefaultComponent, Attach = ConeRotate1)
	UFauxPhysicsConeRotateComponent ConeRotate2;

	UPROPERTY(DefaultComponent, Attach = ConeRotate2)
	UDarkPortalTargetComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DarkPortalResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		FVector AwayImpulse = ((ActorLocation - FVector::UpVector * 600.0) - TargetComponent.WorldLocation).GetSafeNormal() * 100.0;
		ConeRotate2.ApplyImpulse(TargetComponent.WorldLocation, AwayImpulse);
	}
};