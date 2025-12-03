event void FPinballTriggerOnBallPass(UPinballTriggerComponent TriggerComp, UPinballBallComponent BallComp, bool bEnterTrigger);

enum EPinballTriggerType
{
	AlongPlane,
	FacingCamera,
	Free,
}

UCLASS(NotBlueprintable)
class UPinballTriggerComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	EPinballTriggerType Type = EPinballTriggerType::AlongPlane;

	UPROPERTY(EditAnywhere)
	float Radius = 100;

	UPROPERTY()
	FPinballTriggerOnBallPass OnBallPass;
	
	private float LastEnterTime;
	private float LastExitTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Pinball::GetManager().Triggers.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Pinball::GetManager().Triggers.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Pinball::GetManager().Triggers.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Pinball::GetManager().Triggers.RemoveSingleSwap(this);
	}

	FVector GetNormalOnPlane() const
	{
		switch(Type)
		{
			case EPinballTriggerType::AlongPlane:
				return UpVector.VectorPlaneProject(FVector::ForwardVector).GetSafeNormal();

			case EPinballTriggerType::FacingCamera:
				return FVector::BackwardVector;

			case EPinballTriggerType::Free:
				return UpVector;
		}
	}

	FLinearColor GetColor() const
	{
		switch(Type)
		{
			case EPinballTriggerType::AlongPlane:
				return FLinearColor::Red;

			case EPinballTriggerType::FacingCamera:
				return FLinearColor::Yellow;

			case EPinballTriggerType::Free:
				return FLinearColor::Blue;
		}
	}

	bool IsInTrigger(FVector Start, FVector End) const
	{
		switch(Type)
		{
			case EPinballTriggerType::AlongPlane:
				return IsInsideAlongPlaneTrigger(Start, End);

			case EPinballTriggerType::FacingCamera:
				return IsInsideFacingCameraTrigger(End);

			case EPinballTriggerType::Free:
				return IsInsideFreeTrigger(Start, End);

			default:
				DebugBreak();
		}

		return false;
	}

	private bool IsInsideAlongPlaneTrigger(FVector Start, FVector End) const
	{
		check(Type == EPinballTriggerType::AlongPlane);

		const FVector LocationOnPlane = WorldLocation.VectorPlaneProject(FVector::ForwardVector);
		const FVector StartOnPlane = Start.VectorPlaneProject(FVector::ForwardVector);
		const FVector EndOnPlane = End.VectorPlaneProject(FVector::ForwardVector);

		FVector Intersection;
		if(!Math::IsLineSegmentIntersectingPlane(StartOnPlane, EndOnPlane, GetNormalOnPlane(), LocationOnPlane, Intersection))
			return false;

		float DistanceFromTarget = Intersection.Distance(LocationOnPlane);

		if(DistanceFromTarget > Radius)
			return false;

		return true;
	}

	private bool IsInsideFacingCameraTrigger(FVector Location) const
	{
		check(Type == EPinballTriggerType::FacingCamera);

		const FVector TriggerOnPlane = WorldLocation.VectorPlaneProject(FVector::ForwardVector);
		const FVector LocationOnPlane = Location.VectorPlaneProject(FVector::ForwardVector);

		if(LocationOnPlane.Distance(TriggerOnPlane) > Radius)
			return false;
		
		return true;
	}

	private bool IsInsideFreeTrigger(FVector Start, FVector End) const
	{
		check(Type == EPinballTriggerType::Free);

		FVector Intersection;
		if(!Math::IsLineSegmentIntersectingPlane(Start, End, GetNormalOnPlane(), WorldLocation, Intersection))
			return false;

		float DistanceFromTarget = Intersection.Distance(WorldLocation);

		if(DistanceFromTarget > Radius)
			return false;

		return true;
	}

	bool CanBeInsideTrigger() const
	{
		switch(Type)
		{
			case EPinballTriggerType::AlongPlane:
				return false;

			case EPinballTriggerType::FacingCamera:
				return true;

			case EPinballTriggerType::Free:
				return false;
		}
	}
};

class UPinballTriggerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPinballTriggerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Trigger = Cast<UPinballTriggerComponent>(Component);

		const FVector Normal = Trigger.GetNormalOnPlane();
		const FLinearColor Color = Trigger.GetColor();

		DrawCircle(Trigger.WorldLocation, Trigger.Radius, Color, 3, Normal);

		const FVector InFront = Trigger.WorldLocation + Normal * 100;
		DrawArrow(Trigger.WorldLocation, InFront, Color, 10, 3);
	}
}