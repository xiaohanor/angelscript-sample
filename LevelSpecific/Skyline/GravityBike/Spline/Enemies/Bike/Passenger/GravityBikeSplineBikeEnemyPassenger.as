UCLASS(Abstract)
class AGravityBikeSplineBikeEnemyPassenger : AGravityBikeSplineBikeEnemyDriver
{
	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "LeftAttach")
	UStaticMeshComponent PistolMeshComp;

	UPROPERTY(DefaultComponent, Attach = PistolMeshComp)
	UArrowComponent MuzzleLocationComp;

	FVector GetPistolMuzzleLocation() const override
	{
		return MuzzleLocationComp.WorldLocation;
	}
};