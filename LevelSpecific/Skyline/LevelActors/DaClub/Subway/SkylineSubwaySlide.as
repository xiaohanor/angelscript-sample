

class ASkylineSubwaySlide : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGrappleSlidePointComponent GrapplePoint;
	default GrapplePoint.RelativeLocation = FVector::UpVector * 25.0;
	default GrapplePoint.PreferedDirection = FVector::ForwardVector;
	default GrapplePoint.bForceSlideInPreferredDirection = true;
	default GrapplePoint.PointOfInterestOffset = FVector(2000.0, 0.0, 1000.0);
	default GrapplePoint.LaunchVelocity = 3000.0;
//	default GrapplePoint.ActivationRange = 1500.0;
//	default GrapplePoint.AdditionalVisibleRange = 1000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}




};