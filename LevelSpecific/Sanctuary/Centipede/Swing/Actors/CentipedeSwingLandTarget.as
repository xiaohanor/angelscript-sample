class ACentipedeSwingLandTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor, EditAnywhere)
	UCentipedeSwingLandTargetComponent LandTargetComponent;

	FTransform GetMioTargetTransform() const
	{
		return LandTargetComponent.GetMioTargetTransform();
	}

	FTransform GetZoeTargetTransform() const
	{
		return LandTargetComponent.GetZoeTargetTransform();
	}
}