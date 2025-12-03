UCLASS(Abstract)
class UGravityBikeSplineDriverComponent : UGravityBikeSplinePlayerComponent
{
	default AnimationData.bIsPassenger = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AGravityBikeSpline> GravityBikeClass;

	AGravityBikeSpline SpawnGravityBike()
	{
		if(GravityBike != nullptr)
			return GravityBike;

		if(!devEnsure(GravityBikeClass.IsValid()))
			return nullptr;

		GravityBike = SpawnActor(GravityBikeClass, Owner.ActorLocation, Owner.ActorRotation, n"GravityBikeSpline", true);

		GravityBike.MakeNetworked(this, n"GravityBikeSpline");
		GravityBike.SetActorControlSide(Player);
		check(GravityBikeSpline::GetManager().InitialSpline != nullptr);
		GravityBike.SetSpline(GravityBikeSpline::GetManager().InitialSpline);

		FinishSpawningActor(GravityBike);

		GravityBike.SetDriverAndPassenger(Player, Player.OtherPlayer);
		return GravityBike;
	}
}