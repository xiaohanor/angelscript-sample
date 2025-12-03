class UPrisonBeamElevatorPlayerComponent : UActorComponent
{
	UPROPERTY()
	UAnimSequence Anim;

	UPROPERTY()
	UCurveFloat VerticalCurve;

	UPROPERTY()
	UCurveFloat HorizontalCurve;

	APrisonBeamElevator CurrentElevator;
	bool bGoingUp = true;
}