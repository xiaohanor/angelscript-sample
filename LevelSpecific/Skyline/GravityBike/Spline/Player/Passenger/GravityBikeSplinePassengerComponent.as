UCLASS(Abstract)
class UGravityBikeSplinePassengerComponent : UGravityBikeSplinePlayerComponent
{
	default AnimationData.bIsPassenger = true;

	bool IsPassenger() const override
	{
		return true;
	}
}