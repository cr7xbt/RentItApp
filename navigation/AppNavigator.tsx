import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import LoginScreen from '../screens/LoginScreen';
import HomeScreen from '../screens/HomeScreen';

const Stack = createNativeStackNavigator();

const AppNavigator = () => {
  return (
    <NavigationContainer>
      <Stack.Navigator
        initialRouteName="Login"
        screenOptions={{
          headerStyle: {
            backgroundColor: '#0D1B2A', // Rich dark blue for the navigation bar
          },
          headerTintColor: '#FFFFFF', // White text for the navigation bar
          headerTitleStyle: {
            fontWeight: 'bold', // Bold font for titles
          },
        }}
      >
        <Stack.Screen
          name="Login"
          component={LoginScreen}
          options={{ headerShown: false }} // Hide header for Login screen
        />
        <Stack.Screen
          name="Home"
          component={HomeScreen}
          options={{ title: 'Home Page' }} // You can customize the title here
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;