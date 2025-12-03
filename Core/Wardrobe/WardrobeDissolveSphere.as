class AWardrobeDissolveSphere : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereCollisionComponent SphereComponent;

	default SphereComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default SphereComponent.SetCollisionProfileName(n"NoCollision");

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};