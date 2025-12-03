class USummitKnightHeadComponent : UStaticMeshComponent
{
	UPROPERTY()
	private UStaticMesh DamagedHead;	

	void DamageHead()
	{
		StaticMesh = DamagedHead;

		// Hack transform
		RelativeLocation = FVector(60,0,-150);
		RelativeRotation = FRotator(-20, 0, 0);
		RelativeScale3D = FVector::OneVector * 21.0;
	}
}
