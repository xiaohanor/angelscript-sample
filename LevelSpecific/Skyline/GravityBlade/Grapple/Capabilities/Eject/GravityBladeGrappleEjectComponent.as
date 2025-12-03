struct FGravityBladeGrappleEjectData
{
	UPROPERTY(EditAnywhere, Category = "Eject")
	float Impulse = 1000.0;
	UPROPERTY(EditAnywhere, Category = "Eject")
	float TimeDilation = 0.5;
	UPROPERTY(EditAnywhere, Category = "Eject")
	float GravityScale = 0.1;
	UPROPERTY(EditAnywhere, Category = "Eject")
	float JumpDuration = 1.0;
	UPROPERTY(EditAnywhere, Category = "Eject")
	float SlowAimDuration = 2.0;
	UPROPERTY(EditAnywhere, Category = "Eject")
	float DropDuration = 1.0;
};


event void FOnEjectComplete();
class UGravityBladeGrappleEjectComponent : UActorComponent
{
	FGravityBladeGrappleEjectData EjectData;

	FOnEjectComplete OnEjectComplete;
}