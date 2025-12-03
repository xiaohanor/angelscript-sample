class UEnemyPortraitComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FName PortraitName;

	UPROPERTY(EditAnywhere)
	UTexture2D PortraitImage;

//	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	HealthComp = UBasicAIHealthComponent::Get(Owner);
	}
};