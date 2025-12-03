class UGiantsSkydiveMagnetPlayerComponent : UActorComponent
{
	AGiantsSkydiveMagnetPoint MagnetPoint;

	UFUNCTION(BlueprintCallable)
	void SetMagnetPoint(AGiantsSkydiveMagnetPoint Point)
	{
		// PrintToScreen("SET ASSIST POINT " + Owner.ActorNameOrLabel, 10.0);
		MagnetPoint = Point;
	}
};