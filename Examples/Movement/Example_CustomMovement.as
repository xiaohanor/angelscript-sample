
namespace ExampleMovement
{

	/**
	* Creating a custom movement data allowes you to add custom information about your move
	* or custom settings or functions.
	* A custom movement data needs to setup a custom movement resolver.
	*/
	class UExampleCustomMovementData : USteppingMovementData
	{
		default DefaultResolverType = UExampleCustomMovementResolver;

		float CustomValue = 0;
	}


	/**
	* 
	*/
	class UExampleCustomMovementResolver : USteppingMovementResolver
	{
		default RequiredDataType = UExampleCustomMovementData;

		private const UExampleCustomMovementData ExampleCustomData;

		void PrepareResolver(const UBaseMovementData Movement) override
		{
			Super::PrepareResolver(Movement);

			ExampleCustomData = Cast<UExampleCustomMovementData>(Movement);
			float ExapleDoSomething = ExampleCustomData.CustomValue;
	
		}
	}

}