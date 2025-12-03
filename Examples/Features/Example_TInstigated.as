
UFUNCTION()
void Example_TInstigated()
{
	// TInstigated can be used to easily implement a prioritized and instigated list
	// Many different values can be added, and the one with the highest priority is used
	TInstigated<FName> CollisionProfile;
	CollisionProfile.SetDefaultValue(n"PlayerCharacter");

	// Apply the PriorityNormal value for Mio as instigator
	CollisionProfile.Apply(n"PriorityNormal", Game::Mio);

	// Apply the PriorityLow value for Zoe as instigator at low priority
	CollisionProfile.Apply(n"PriorityLow", Game::Zoe, EInstigatePriority::Low);

	Print("Collision Profile is: "+CollisionProfile.Get());

	// The highest pririoty value we have set is with instigator Mio
	check(CollisionProfile.Get() == n"PriorityNormal");

	// Clear the value set by Mio
	CollisionProfile.Clear(Instigator = Game::Mio);

	// After clearing Mio, Zoe's instigator is setting a low priority value still
	check(CollisionProfile.Get() == n"PriorityLow");

	// Clear the value set by Zoe
	CollisionProfile.Clear(Instigator = Game::Zoe);

	// Neither value is available anymore, so we should now have the original default value
	check(CollisionProfile.Get() == n"PlayerCharacter");
}

struct FExample_InstigatedData
{
	FVector Position;
	bool bToggle = false;
};

UFUNCTION()
void Example_TInstigated_Struct()
{
	// It is also possible to use any struct data with TInstigated
	TInstigated<FExample_InstigatedData> InstigatedData;

	FExample_InstigatedData AddedData;
	AddedData.Position.Z = 100.0;
	AddedData.bToggle = true;

	// As with all instigators, it's also possible to use an FName as instigator
	InstigatedData.Apply(AddedData, Instigator = n"NamedInstigator");
	InstigatedData.Clear(n"NamedInstigator");

	Print("Position: "+InstigatedData.Get().Position);
}