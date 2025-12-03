class USkylineTorHammerBulletComponent : USceneComponent
{
	bool bEnabled;

	UPROPERTY()
	TSubclassOf<ASkylineTorHammerBullet> HammerBulletClass;
}